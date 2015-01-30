package Plack::Session::State::URI;

use parent 'Plack::Session::State';
use strict;
use warnings;

use Encode ();
use HTML::StickyQuery;
use HTTP::Status qw/HTTP_FOUND HTTP_OK/;
use Plack::Request;
use Plack::Util;

our $DefaultEncoding = 'utf8';
our $VERSION = '0.06';

sub get_session_id {
    my ($self, $env) = @_;

    Plack::Request->new($env)->param($self->session_key);
}

sub finalize {
    my ($self, $id, $res) = @_;

    return unless $id;

    if ($res->[0] == HTTP_OK) {
        $self->html_filter($id, $res);
    } elsif ($res->[0] == HTTP_FOUND) {
        $self->redirect_filter($id, $res);
    }
}

sub html_filter {
    my ($self, $id, $res) = @_;

    return if (ref $res->[2]) ne 'ARRAY';

    my $h = Plack::Util::headers($res->[1]);
    my $body = _get_body($res);
    my $encoding = _parse_encoding($h);

    $body = Encode::decode($encoding, $body);

    $body = $self->_html_filter_body($body, $id);

    $body = Encode::encode($encoding, $body);

    $res->[2] = [$body];
}

sub redirect_filter {
    my ($self, $id, $res) = @_;

    my $h = Plack::Util::headers($res->[1]);
    my $loc = $h->get('Location');
    my $uri = URI->new($loc);

    $uri->query_form( $uri->query_form, $self->session_key, $id );
    $h->set('Location', $uri->as_string);
}

sub _get_body {
    my ($res) = @_;
    my $body = '';

    for my $line (@{ $res->[2] }) {
        $body .= $line if length $line;
    }

    return $body;
}

sub _html_filter_body {
    my ($self, $body, $id) = @_;

    my $name = $self->session_key;
    my $input = qq{<input type="hidden" name="$name" value="$id" />};

    $body =~ s{(<form\s*.*?>)}{$1\n}isg;

    my $sticky = HTML::StickyQuery->new;

    $body = $sticky->sticky(
        scalarref => \$body,
        param     => { $name => $id }
    );

    return $body;
}

sub _parse_encoding {
    my ($h) = @_;

    my $content_type = $h->get('Content-Type');

    if ($content_type =~ m|^text/\w+;\s*charset="?([^"]+)"?|i) {
        return $1;
    }

    return $DefaultEncoding;
}

1;

=head1 NAME

Plack::Session::State::URI - uri-based session state

=head1 SYNOPSIS

  use File::Temp qw/tempdir/;
  use HTML::Status qw/HTTP_OK/;
  use Plack::Builder;
  use Plack::Session::Store::File;
  use Plack::Session::State::URI;

  my $app = sub {
      return [
          HTTP_OK,
          ['Content-Type' => 'text/plain'],
          ['Hello Foo']
      ];
  };

  builder {
      my $tmpdir = tempdir('XXXXXXXX', CLEANUP => 1, TMPDIR => 1);
      my $store = Plack::Session::Store::File->new(dir => $tmpdir);
      my $state = Plack::Session::State::URI->new(session_key => 'sid');

      enable 'Session', store => $store, state => $state;

      $app;
  };

=head1 DESCRIPTION

Plack::Session::State::URI is uri-based session state

=head1 AUTHOR

Shinichiro Aska E<lt>s.aska.org {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
