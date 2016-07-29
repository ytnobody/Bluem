use strict;
use warnings;
use Test::More;
use Bluem::DB;
use File::Temp 'tempdir';
use File::Spec;

$Bluem::DB::STORAGE_PATH = tempdir(CLEANUP => 1);

subtest 'new' => sub {
    my $db = Bluem::DB->new('foo');
    isa_ok $db, 'Bluem::DB';
    my $entry_file = File::Spec->catfile($Bluem::DB::STORAGE_PATH, 'foo-entry.txt');
    is $db->path('entry'), $entry_file;
    my $blacklist_file = File::Spec->catfile($Bluem::DB::STORAGE_PATH, 'foo-blacklist.txt');
    is $db->path('blacklist'), $blacklist_file;
};

subtest 'entry' => sub {
    my @data = (1 .. 13);
    my $db = Bluem::DB->new('foo');
    $db->add(entry => @data);
    my @rows = $db->get('entry');
    is_deeply [@rows], [@data];
};

subtest 'blacklist' => sub {
    my @data = qw/4 7 8/;
    my $db = Bluem::DB->new('foo');
    $db->add(blacklist => @data);
    my @rows = $db->get('blacklist');
    is_deeply [@rows], [@data];
};

subtest 'get_filtered' => sub {
    my $db = Bluem::DB->new('foo');
    my $data = $db->get_filtered(page => 2, num => 3);
    isa_ok $data, 'HASH';
    is_deeply $data, {
        page => 2,
        from => 4,
        to   => 6,
        rows => [qw/5 6 9/],
        next_page => 1,
    };

    $data = $db->get_filtered(page => 4, num => 3);
    isa_ok $data, 'HASH';
    is_deeply $data, {
        page => 4,
        from => 10,
        to   => 12,
        rows => [qw/13/],
        next_page => 0,
    };
};

done_testing;
__END__

subtest 'flush' => sub {
    Bluem::DB->flush(foo => 'blacklist');
    my @rows = Bluem::DB->blacklist('foo');
    is_deeply [@rows], [];

    Bluem::DB->flush(foo => 'entry');
    @rows = Bluem::DB->entries('foo');
    is_deeply [@rows], [];
};

done_testing;