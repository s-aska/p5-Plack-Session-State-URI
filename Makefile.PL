use inc::Module::Install;
name 'Plack-Session-State-URI';
all_from 'lib/Plack/Session/State/URI.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
