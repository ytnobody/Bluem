use strict;
use warnings;
use Test::More;
use Plack::Test;
use Bluem;
use File::Temp 'tempdir';
use HTTP::Request::Common;
use JSON;
use Benchmark qw/timeit timestr/;

$Bluem::DB::STORAGE_PATH = tempdir(CLEANUP => 1); 

my $app = Bluem->app;
my $test = Plack::Test->create($app);
my $JSON = JSON->new->utf8(1);

subtest 'add entry' => sub {
    my $iter = 1;
    my $time = timeit(1000, sub {
        warn "$iter to ". ($iter+999);
        my $res = $test->request(
            POST '/v1/foo/entry', 
            'Content-Type' => 'application/json',
            'Content' => $JSON->encode({
                rows => [
                    map { {id => $_, data => 'name=foo'.$_} } $iter .. $iter+999 
                ],
            })
        );
        $iter += 1000;
    });
    diag timestr($time);
    ok 1;
};

done_testing;