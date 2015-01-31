use strict;
use utf8;
use warnings;

use Data::Dumper;
use File::Temp;
use Fcntl qw/SEEK_END/;
use HTTP::Request::Common;
use HTML::TreeBuilder::XPath;
use Plack::Builder;
use Plack::Request;
use Plack::Session::State::URI;
use Plack::Session::Store::File;
use Plack::Session;
use Plack::Test;
use Readonly;
use Test::Simple tests => 10;

sub escape_js_string {
    my ($fake_form) = @_;

    $fake_form =~ s/"/\\"/g;

    return $fake_form;
}

Readonly::Scalar my $fake_form => '<form id="fake"></form>';
Readonly::Scalar my $bad_attr => qq/data-breaking-attribute='$fake_form'/;
Readonly::Scalar my $js_str_fake_form => escape_js_string($fake_form);
Readonly::Scalar my $sid => 'sid';
Readonly::Scalar my $base_re => qr/.*fake.*\n?.*$sid/;

Readonly::Scalar my $html => <<EOF;
<style type="text/css" $bad_attr>
    /*css $fake_form */
</style>
<script type="text/javascript" $bad_attr>
    <!--
    var html = "$js_str_fake_form";
    // $fake_form
    /*js $fake_form */
    -->
</script>
<form id="real" $bad_attr>
    <!-- $fake_form -->
    <label for="name" $bad_attr>Name:</label>
    <input type="text" id="name" name="name" $bad_attr />
</form>
EOF

my $app = builder {
    my $dir = File::Temp->newdir('XXXXXXXX',
            CLEANUP => 1,
            TEMPDIR => 1,
            TMPDIR => 1);

    my $store = Plack::Session::Store::File->new(dir => $dir),
    my $state = Plack::Session::State::URI->new(session_key => $sid);

    enable 'Session', store => $store, state => $state;

    sub {
        my ($env) = @_;
        my $req = Plack::Request->new($env);
        my $session = Plack::Session->new($env);

        if (defined $req->param('data')) {
            $session->set('data', $req->param('data'));
        }

        my $data = $session->get('data');

        $data = '' unless defined $data;

        if (my $url = $req->param('url')) {
            [
                302,
                ['Location', $url],
                ['']
            ];
        } else {
            [
                200,
                ['Content-Type', 'text/html; charset="UTF-8"'],
                [$html]
            ]
        }
    }
};

my ($log_fh, $log_fn);

my $log_notice = 0;

sub log_result {
    my ($desc, @test_params) = @_;

    unless ($log_notice) {
        ($log_fh, $log_fn) =
                File::Temp::tempfile(SUFFIX => 'Plack-Session-State-URI');

        if (defined $log_fh) {
            warn "# More verbose test results are being logged to ",
                    "$log_fn.\n";
            binmode $log_fh, ':utf8';
        } else {
            warn "# Failed to create temporary log file. ",
                    "I would have logged more verbosely to it.\n";
        }

        $log_notice = 1;
    }

    unless (defined $log_fh) {
        return;
    }

    print $log_fh "Description: $desc\n";

    for(my ($i, $l) = (0, scalar @test_params); $i<$l; $i+=2) {
        printf $log_fh "%s: %s\n", @test_params[$i, $i + 1];
    }

    print $log_fh "---\n";
}

sub test_result {
    my ($desc, $result, $test_params, %named_params) = @_;

    if ($named_params{negate}) {
        $result = !$result;
    }

    if (!$result) {
        log_result($desc, @$test_params);
    }

    ok $result, $desc;
}

sub test_lambda {
    my ($desc, $content ,$lambda, %named_params) = @_;

    my @test_params;

    my $result = $lambda->($content, \@test_params);

    {
        chomp(my $dump = Data::Dumper->Dump([$result], ['result']));

        push @test_params,
                'Negated (Match is bad)' =>
                        $named_params{negate} ? "yes" : "no",
                'Result' => $dump;
    }

    test_result($desc, $result, \@test_params, %named_params);
}

sub test_match {
    my ($desc, $content, $re, %named_params) = @_;

    my @matches = $content =~ /($re)/;

    my $test_params = do {
        local $" = "», «";

        [
            'Regular expression' => "«$re»",
            'Negated (Match is bad)' =>
                    $named_params{negate} ? "yes" : "no",
            'Matches' => "«@matches»"
        ];
    };

    my $result = @matches;

    test_result($desc, $result, $test_params, %named_params);
}

test_psgi $app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET '/');

    my $content = $res->content;

    test_match(
            'embedded HTML <form> in <style> attribute',
            $content,
            qr/<style$base_re/,
            negate => 1);

    test_match(
            'embedded HTML <form> in CSS /**/ comment',
            $content,
            qr{/\*css$base_re},
            negate => 1);

    test_match(
            'embedded HTML <form> in <script> attribute',
            $content,
            qr/<script$base_re/,
            negate => 1);

    test_match(
            'embedded HTML <form> in JavaScript string',
            $content,
            qr/(var$base_re)/,
            negate => 1);

    test_match(
            'embedded HTML <form> in JavaScript line comment',
            $content,
            qr{//$base_re},
            negate => 1);

    test_match(
            'embedded HTML <form> in JavaScript block comment',
            $content,
            qr{/\*js$base_re},
            negate => 1);

    test_match(
            'embedded HTML <form> in <form> attribute',
            $content,
            qr|
                <form\ id="real"
                .*?
                <form\ id="fake">
                [\n\s]*
                <input
                [^>]+
                $sid
            |x,
            negate => 1);

    test_match(
            'embedded HTML <form> in <form> <label> attribute',
            $content,
            qr/<label$base_re/,
            negate => 1);

    test_match(
            'embedded HTML <form> in <form> <input> attribute',
            $content,
            qr/<input.*id="name"$base_re/,
            negate => 1);

    test_lambda(
            'real <form> has session identifier hidden <input>' =>
            $content,
            sub {
                my ($content, $test_params) = @_;

                my $parser = 'HTML::TreeBuilder::XPath';

                push @$test_params, 'Parser' => $parser;

                my $tree = $parser->new_from_content($content);

                my $xpath = sprintf q{//form//input[@name='%s']}, $sid;

                push @$test_params, 'XPath' => "«$xpath»";

                my ($node) = $tree->findnodes($xpath);

                unless ($node) {
                    (my $indented = "«$content»") =~ s/^/' ' x 8/egm;

                    push @$test_params, 'Content' => "\n$indented";
                }

                return $node;
            });
};
