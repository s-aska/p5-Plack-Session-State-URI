requires 'perl', '5.008001';

requires 'HTML::StickyQuery';
requires 'Plack';
requires 'Plack::Middleware::Session';

on test => sub {
    requires 'HTML::TreeBuilder::XPath';
    requires 'HTTP::Request::Common';
    requires 'Readonly';
    requires 'Test::More';
};
