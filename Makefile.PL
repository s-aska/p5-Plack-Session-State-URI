use inc::Module::Install;
name 'Plack-Session-State-URI';
all_from 'lib/Plack/Session/State/URI.pm';

tests 't/*.t';

auto_include;
resources
    license     => "http://dev.perl.org/licenses",
    repository  => "https://github.com/s-aska/p5-Plack-Session-State-URI";
cpanfile;
WriteAll;
