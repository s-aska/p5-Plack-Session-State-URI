use inc::Module::Install;
name 'Plack-Session-State-URI';
all_from 'lib/Plack/Session/State/URI.pm';

requires 'Plack';
requires 'Plack::Middleware::Session';
requires 'HTML::StickyQuery';

tests 't/*.t';

test_requires 'Test::More';
test_requires 'HTTP::Request::Common';

auto_include;
resources
    license     => "http://dev.perl.org/licenses",
    repository  => "https://github.com/s-aska/p5-Plack-Session-State-URI";
WriteAll;
