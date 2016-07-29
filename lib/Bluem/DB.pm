package Bluem::DB;
use strict;
use warnings;
use File::Spec;
use Bloom::Filter;
use Carp;
use Guard 'guard';

our $STORAGE_PATH = File::Spec->catdir(qw[/ var bluem ]);
our $ERROR_RATE   = 0.005;

sub new {
    my ($class, $dbname) = @_;
    croak 'dbname is required' if !$dbname;
    my $entry = File::Spec->catfile($STORAGE_PATH, "$dbname-entry.txt");
    my $blacklist = File::Spec->catfile($STORAGE_PATH, "$dbname-blacklist.txt");
    bless {entry => $entry, blacklist => $blacklist}, $class;
}

sub path {
    my ($self, $item) = @_;
    $self->{$item};
}

sub fh {
    my ($self, $item, $mode) = @_;
    open my $fh, $mode, $self->{$item} or croak $!;
    $fh;
}

sub add {
    my ($self, $item, @ids) = @_;
    my $fh = $self->fh($item, '>>');
    print $fh join("\n", @ids)."\n";
    close $fh;
}

sub get {
    my ($self, $item) = @_;
    my $fh = $self->fh($item, '<');
    my @ids = <$fh>;
    close $fh;
    map {s/\n//r} @ids;
}

sub flush {
    my ($self, $item) = @_;
    my $fh = $self->fh($item, '>');
    print $fh "";
    close $fh;
}

sub get_filtered {
    my ($self, %param) = @_;
    my $page      = $param{page} || 1;
    my $num       = $param{num} || 10;
    my @entry     = $self->get('entry');
    my @blacklist = $self->get('blacklist');
    my $bloom     = Bloom::Filter->new(capacity => scalar(@blacklist), error_rate => $ERROR_RATE);
    $bloom->add(@blacklist);
    my @filtered = grep {!$bloom->check($_)} @entry;
    @entry  = undef;
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
