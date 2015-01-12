#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Plack::Session::State::URI') or print "Bail out!\n";
}

my $version = $Plack::Session::State::URI::VERSION;

diag("Testing Plack::Session::State::URI $version, Perl $], $^X");
