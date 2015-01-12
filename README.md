[![Build Status](https://travis-ci.org/s-aska/p5-Plack-Session-State-URI.png?branch=master)](https://travis-ci.org/s-aska/p5-Plack-Session-State-URI)
# NAME

Plack::Session::State::URI - uri-based session state

# SYNOPSIS

    use File::Temp qw/tempdir/;
    use HTTP::Status qw/HTTP_OK/;
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

# DESCRIPTION

Plack::Session::State::URI is uri-based session state

# AUTHOR

Shinichiro Aska <s.aska.org {at} gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
