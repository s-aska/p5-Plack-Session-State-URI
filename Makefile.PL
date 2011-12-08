use inc::Module::Install;
name 'Plack-Session-State-URI';
all_from 'lib/Plack/Session/State/URI.pm';

requires 'Plack';
requires 'HTML::StickyQuery';

tests 't/*.t';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
