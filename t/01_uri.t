use strict;
use warnings;

use File::Temp;
use HTTP::Request::Common;
use HTTP::Status qw/HTTP_FOUND HTTP_OK/;
use Plack::Builder;
use Plack::Request;
use Plack::Session::State::URI;
use Plack::Session::Store::File;
use Plack::Session;
use Plack::Test;
use Test::More;

my $app = builder {
    my $dir = File::Temp->newdir('XXXXXXXX',
            CLEANUP => 1,
            TEMPDIR => 1,
            TMPDIR => 1);

    my $store = Plack::Session::Store::File->new(dir => $dir),
    my $state = Plack::Session::State::URI->new(session_key => 'sid');

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
                HTTP_FOUND,
                ['Location', $url],
                ['']
            ];
        } else {
            [
                HTTP_OK,
                ['Content-Type', 'text/html; charset="UTF-8"'],
                [qq{<a href="/?foo=1">ok</a><p>$data</p>}]
            ]
        }
    }
};

test_psgi $app, sub {
    my ($cb) = @_;

    my $data = 'param1';

    my $res = $cb->(GET '/?data=' . $data);
    my ($sid) = $res->content =~ m|sid=(\w+)|;

    ok $sid, 'sid generate.';

    my $res2 = $cb->(GET '/?sid=' . $sid);
    my ($sid2) = $res2->content =~ m|sid=(\w+)|;

    is $sid, $sid2, 'sid equal.';

    my ($data2) = $res2->content =~ m|<p>(.*)</p>|;

    is $data, $data2, 'data equal.';

    my $res3 = $cb->(GET '/?url=http://example.org/&sid=' . $sid);
    my ($sid3) = $res3->header('Location') =~ m|sid=(\w+)|;

    is $sid, $sid3, 'sid equal. (redirect)';

    my $res4 = $cb->(GET '/');
    my ($sid4) = $res4->content =~ m|sid=(\w+)|;

    isnt $sid, $sid4, 'new sid generate.'
};

done_testing();
