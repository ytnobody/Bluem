package Bluem;
use 5.008001;
use strict;
use warnings;
use Amagi;
use Bluem::DB;

our $VERSION = "0.01";

get "/v1/list" => sub {
    my ($app, $req) = @_;
    my @db_list = Bluem::DB->list;
    {dbs => [@db_list]};
};

post "/v1/:dbname/:table" => sub {
    my ($app, $req) = @_;
    my $json  = $req->json_content;
    my $dbname = $req->captured->{dbname};
    my $table = $req->captured->{table};
    my $method = "add_$table";
    Bluem::DB->$method($dbname => @{$json->{rows}});
    {message => "done"};
};

get "/v1/:dbname" => sub {
    my ($app, $req) = @_;
    my $page = $req->param('page') || 1;
    my $num  = $req->param('rows') || 10;
    my $dbname = $req->captured->{dbname};
    Bluem::DB->get_filtered($dbname => (page => $page, num => $num));
};

post "/v1/:dbname/:table/delete" => sub {
    my ($app, $req) = @_;
    my $dbname = $req->captured->{dbname};
    my $table  = $req->captured->{table};
    Bluem::DB->flush($dbname => $table);
    {message => "done"};
};

1;
__END__

=encoding utf-8

=head1 NAME

Bluem - It's new $module

=head1 SYNOPSIS

    use Bluem;

=head1 DESCRIPTION

Bluem is ...

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

