package Bluem::DB;
use strict;
use warnings;
use Otogiri;
use Otogiri::Plugin;
use File::Spec;
use Bloom::Filter;

Otogiri->load_plugin('BulkInsert');

our $STORAGE_PATH = File::Spec->catdir(qw[/ var bluem ]);
our $ERROR_RATE   = 0.005;

sub new {
    my ($class, $dbname) = @_;
    my $path  = File::Spec->catfile($STORAGE_PATH, "$dbname.sqlite3");
    my $dsn   = "dbi:SQLite:dbname=$path";
    my $db    = Otogiri->new($dsn, "", "");
    my $query = do { local $/; <DATA>};
    $db->do($query);
    $db;
}

sub list {
    my ($class) = @_;
    map {s[\.sqlite3][]r} map {s[$STORAGE_PATH/][]r} glob "$STORAGE_PATH/*.sqlite3";
}

sub get_filtered {
    my ($class, %param) = @_;
    my $dbname    = $param{dbname};
    my $page      = $param{page} || 1;
    my $num       = $param{num} || 10;
    my $db        = $class->init($dbname);
    my @entries   = $class->select(entry => {}, {order => "ctime"});
    my @blacklist = $class->select('blacklist');
    my $bloom     = Bloom::Filter->new(capacity => scalar(@blacklist), error_rate => $ERROR_RATE);
    $bloom->add(map {$_->{id}} @blacklist);
    my @filtered = grep {$bloom->check($_->{id})} @entries;
    @entries = ();
    my $rtn = {
        page      => $page,
        from      => $num * ($page - 1) + 1,
        to        => $num * $page,
    };
    $rtn->{rows} = grep {defined $_} @filtered[$rtn->{from}-1 .. $rtn->{to}-1];
    $rtn->{next_page} = $filtered[$rtn->{to}] ? 1 : 0;
    return $rtn;
}

1;
__DATA__
CREATE TABLE IF NOT EXISTS blacklist (
    id text,
    data text,
    ctime int
);
CREATE TABLE IF NOT EXISTS entry (
    id text,
    data text,
    ctime int
);