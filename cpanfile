requires 'perl', '5.008001';

requires 'HTML::StickyQuery';
requires 'Plack';
requires 'Plack::Middleware::Session';

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Test::More';
};
