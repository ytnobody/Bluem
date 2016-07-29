use strict;
use warnings;
use Test::More;
use Plack::Test;
use Bluem;
use File::Temp 'tempdir';
use HTTP::Request::Common;
use JSON;

$Bluem::DB::STORAGE_PATH = tempdir(CLEANUP => 1); 

my $app = Bluem->app;
my $test = Plack::Test->create($app);
my $JSON = JSON->new->utf8(1);

subtest 'add entry' => sub {
    my $res = $test->request(
        POST '/v1/foo/entry', 
        'Content-Type' => 'application/json', 
        'Content'      => $JSON->encode({
            rows => [qw/foo1 foo2 foo3 foo4/],
        })
    );
    ok $res->is_success, 'request succeed';
};

subtest 'add blacklist' => sub {
    my $res = $test->request(
        POST '/v1/foo/blacklist', 
        'Content-Type' => 'application/json', 
        'Content'      => $JSON->encode({
            rows => ['foo2'],
        })
    );
    ok $res->is_success, 'request succeed';
};

subtest 'get filtered' => sub {
    my $res = $test->request(GET '/v1/foo');
    ok $res->is_success, 'request succeed';
    my $data = $JSON->decode($res->content);
    isa_ok $data->{rows}, 'ARRAY';
    is_deeply $data->{rows}, [qw/foo1 foo3 foo4/];
    is $data->{next_page}, 0; 
};

subtest 'flush blacklist and entry' => sub {
    my $res = $test->request(POST '/v1/foo/entry/delete');
    ok $res->is_success, 'request succeed';
    $res = $test->request(POST '/v1/foo/blacklist/delete');
    ok $res->is_success, 'request succeed';    
};

done_testing;