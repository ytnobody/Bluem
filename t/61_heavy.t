use strict;
use warnings;
use Test::More;
use Plack::Test;
use Bluem;
use File::Temp 'tempdir';
use HTTP::Request::Common;
use JSON;
use Time::HiRes;

$Bluem::DB::STORAGE_PATH = tempdir(CLEANUP => 1); 

my $app = Bluem->app;
my $test = Plack::Test->create($app);
my $JSON = JSON->new->utf8(1);

subtest 'add blacklist' => sub {
    my $rows = [map {$_ * 3} 1 .. 500000];
    my $begin = Time::HiRes::time();
    my $res = $test->request(
        POST '/v1/foo/blacklist', 
        'Content-Type' => 'application/json',
        'Content' => $JSON->encode({
            rows => $rows,
        })
    );
    my $end = Time::HiRes::time();
    ok $res->is_success, 'request is success';
    ok $end-$begin < 5, 'time elapsed 5 sec. or faster: we got '. ($end-$begin);
};

subtest 'add entry' => sub {
    my $rows = [1 .. 3000000];
    my $begin = Time::HiRes::time();
    my $res = $test->request(
        POST '/v1/foo/entry', 
        'Content-Type' => 'application/json',
        'Content' => $JSON->encode({
            rows => $rows,
        })
    );
    my $end = Time::HiRes::time();
    ok $res->is_success, 'request is success';
    ok $end-$begin < 30, 'time elapsed 30 sec. or faster: we got '. ($end-$begin);
};

subtest 'get filtered 3000000 - 500000' => sub {
    my $begin = Time::HiRes::time();
    my $res = $test->request(GET '/v1/foo?page=20&rows=20');
    my $end = Time::HiRes::time();
    ok $res->is_success, 'request succeed';
    ok $end-$begin < 5, '[3000000 - 500000]time elapsed 5 sec. or faster: we got '. ($end-$begin);
};

subtest 'get filtered 3000000 - 100' => sub {
    $test->request(POST '/v1/foo/blacklist/delete');
    my $rows = [map {$_ * 3} 1 .. 100];
    $test->request(
        POST '/v1/foo/blacklist', 
        'Content-Type' => 'application/json',
        'Content' => $JSON->encode({
            rows => $rows,
        })
    );

    my $begin = Time::HiRes::time();
    my $res = $test->request(GET '/v1/foo?page=20&rows=20');
    my $end = Time::HiRes::time();
    ok $res->is_success, 'request succeed';
    ok $end-$begin < 30, '[3000000 - 100]time elapsed 30 sec. or faster: we got '. ($end-$begin);
};

subtest 'get filtered 1000 - 100' => sub {
    $test->request(POST '/v1/foo/entry/delete');
    my $rows = [1 .. 1000];
    $test->request(
        POST '/v1/foo/entry', 
        'Content-Type' => 'application/json',
        'Content' => $JSON->encode({
            rows => $rows,
        })
    );

    my $begin = Time::HiRes::time();
    my $res = $test->request(GET '/v1/foo?page=20&rows=20');
    my $end = Time::HiRes::time();
    ok $res->is_success, 'request succeed';
    ok $end-$begin < 5, '[1000 - 100]time elapsed 5 sec. or faster: we got '. ($end-$begin);
};


subtest 'get filtered 1000 - 500' => sub {
    $test->request(POST '/v1/foo/blacklist/delete');
    my $rows = [map {$_ * 3} 1 .. 500];
    my $res = $test->request(
        POST '/v1/foo/blacklist', 
        'Content-Type' => 'application/json',
        'Content' => $JSON->encode({
            rows => $rows,
        })
    );

    my $begin = Time::HiRes::time();
    my $res = $test->request(GET '/v1/foo?page=20&rows=20');
    my $end = Time::HiRes::time();
    ok $res->is_success, 'request succeed';
    ok $end-$begin < 5, '[1000 - 500]time elapsed 5 sec. or faster: we got '. ($end-$begin);
};

done_testing;