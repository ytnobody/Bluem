package Bluem::DB;
use strict;
use warnings;
use Otogiri;
use Otogiri::Plugin;
use File::Spec;
use Bloom::Filter;
use Carp;

Otogiri->load_plugin('BulkInsert');
Otogiri->load_plugin('TableInfo');

our $STORAGE_PATH = File::Spec->catdir(qw[/ var bluem ]);
our $ERROR_RATE   = 0.005;

sub new {
    my ($class, $dbname) = @_;
    croak 'dbname is required' if !$dbname;
    my $path  = File::Spec->catfile($STORAGE_PATH, "$dbname.sqlite3");
    my $dsn   = "dbi:SQLite:dbname=$path";
    my $db    = Otogiri->new(connect_info => [$dsn, "", ""], strict => 0);

    $db->do(<<SQL);
CREATE TABLE IF NOT EXISTS blacklist (
    id text,
    ctime int
);
SQL

    $db->do(<<SQL);
CREATE TABLE IF NOT EXISTS entry (
    id text,
    data text,
    ctime int
);
SQL
    $db;
}

sub list {
    my ($class) = @_;
    map {s[\.sqlite3][]r} map {s[$STORAGE_PATH/][]r} glob "$STORAGE_PATH/*.sqlite3";
}

sub add_entry {
    my ($class, $dbname, @rows) = @_;
    my $db = $class->new($dbname);
    my $now = time;
    $db->bulk_insert(entry => [qw/id data ctime/], [map {$_->{ctime} = $now; $_} @rows]);
}

sub add_blacklist {
    my ($class, $dbname, @idlist) = @_;
    my $db = $class->new($dbname);
    my $now = time;
    $db->bulk_insert(blacklist => [qw/id ctime/], [map {{ctime => $now, id => $_}} @idlist]);
}

sub entries {
    my ($class, $dbname) = @_;
    my $db = $class->new($dbname);
    $db->select(entry => {}, {order => 'ctime'});
}

sub blacklist {
    my ($class, $dbname) = @_;
    my $db = $class->new($dbname);
    $db->select('blacklist');
}

sub flush {
    my ($class, $dbname, $table) = @_;
    my $db = $class->new($dbname);
    $db->delete($table);
}

sub get_filtered {
    my ($class, $dbname, %param) = @_;
    my $page      = $param{page} || 1;
    my $num       = $param{num} || 10;
    my @entries   = $class->entries($dbname);
    my @blacklist = $class->blacklist($dbname);
    my $bloom     = Bloom::Filter->new(capacity => scalar(@blacklist), error_rate => $ERROR_RATE);
    $bloom->add(map {$_->{id}} @blacklist);
    my @filtered = grep {!$bloom->check($_->{id})} @entries;
    @entries = ();
    my $rtn = {
        page      => $page,
        from      => $num * ($page - 1) + 1,
        to        => $num * $page,
    };
    $rtn->{rows} = [grep {defined $_} @filtered[$rtn->{from}-1 .. $rtn->{to}-1]];
    $rtn->{next_page} = $filtered[$rtn->{to}] ? 1 : 0;
    return $rtn;
}

1;
__DATA__
