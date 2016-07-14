use strict;
use warnings;
use Test::More;
use Bluem::DB;
use File::Temp 'tempdir';
use File::Spec;

$Bluem::DB::STORAGE_PATH = tempdir(CLEANUP => 1);

subtest 'new' => sub {
    my $db = Bluem::DB->new('foo');
    isa_ok $db, 'DBIx::Otogiri';
    my $dbfile = File::Spec->catfile($Bluem::DB::STORAGE_PATH, 'foo.sqlite3');
    ok -f $dbfile, 'database file was created';
    my @tables = sort $db->show_tables;
    is_deeply [@tables], [qw[blacklist entry]];
};

subtest 'list' => sub {
    Bluem::DB->new('bar');
    Bluem::DB->new('baz');
    my @rows = sort Bluem::DB->list;
    is_deeply [@rows], [qw[bar baz foo]];
};

subtest 'entries' => sub {
    my @data = (
        {id => 1, data => 'name=foo&age=31'},
        {id => 2, data => 'name=bar&age=32'},
        {id => 3, data => 'name=baz&age=12'},
        {id => 4, data => 'name=hoge&age=9'},
        {id => 5, data => 'name=fuga&age=38'},
        {id => 6, data => 'name=piyo&age=24'},
        {id => 7, data => 'name=boo&age=52'},
        {id => 8, data => 'name=bee&age=80'},
        {id => 9, data => 'name=uno&age=49'},
        {id => 10, data => 'name=dos&age=14'},
        {id => 11, data => 'name=tres&age=83'},
        {id => 12, data => 'name=quad&age=77'},
        {id => 13, data => 'name=penta&age=31'},
    );
    Bluem::DB->add_entry(foo => @data);
    my @rows = Bluem::DB->entries('foo');
    is_deeply [@rows], [@data];
    is_deeply [sort keys %{$rows[0]}], [qw[ctime data id]];
};

subtest 'blacklist' => sub {
    Bluem::DB->add_blacklist(foo => qw/4 7 8/);
    my @blacklist = Bluem::DB->blacklist('foo');
    is_deeply [sort map {$_->{id}} @blacklist], [qw/4 7 8/];
    is_deeply [sort keys %{$blacklist[0]}], [qw[ctime id]];
};

subtest 'get_filtered' => sub {
    my $data = Bluem::DB->get_filtered(foo => (page => 2, num => 3));
    isa_ok $data, 'HASH';
    for my $row (@{$data->{rows}}) {
        delete $row->{ctime};
    }
    is_deeply $data, {
        page => 2,
        from => 4,
        to   => 6,
        rows => [
            {id => 5, data => 'name=fuga&age=38'},
            {id => 6, data => 'name=piyo&age=24'},
            {id => 9, data => 'name=uno&age=49'},        
        ],
        next_page => 1,
    };

    $data = Bluem::DB->get_filtered(foo => (page => 4, num => 3));
    isa_ok $data, 'HASH';
    for my $row (@{$data->{rows}}) {
        delete $row->{ctime};
    }
    is_deeply $data, {
        page => 4,
        from => 10,
        to   => 12,
        rows => [
            {id => 13, data => 'name=penta&age=31'},
        ],
        next_page => 0,
    };
};

subtest 'flush' => sub {
    Bluem::DB->flush(foo => 'blacklist');
    my @rows = Bluem::DB->blacklist('foo');
    is_deeply [@rows], [];

    Bluem::DB->flush(foo => 'entry');
    @rows = Bluem::DB->entries('foo');
    is_deeply [@rows], [];
};

done_testing;