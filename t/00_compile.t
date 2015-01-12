#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Plack::Session::State::URI') or print "Bail out!\n";
}

diag("Testing Plack::Session::State::URI $Plack::Session::State::URI::VERSION, Perl $], $^X");
