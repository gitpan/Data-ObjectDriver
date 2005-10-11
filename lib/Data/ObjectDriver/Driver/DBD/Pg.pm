# $Id: Pg.pm 964 2005-08-01 08:01:02Z btrott $

package Data::ObjectDriver::Driver::DBD::Pg;
use strict;
use base qw( Data::ObjectDriver::Driver::DBD );

sub init_dbh {
    my $dbd = shift;
    my($dbh) = @_;
    $dbh->do("set timezone to 'UTC'");
    $dbh;
}

sub bind_param_attributes {
    my ($dbd, $data_type) = @_;
    if ($data_type && $data_type eq 'blob') {
        return { pg_type => DBD::Pg::PG_BYTEA() };
    }
    return undef;
}

sub sequence_name {
    my $dbd = shift;
    my($class) = @_;
    join '_', $class->datasource, $class->properties->{primary_key}, 'seq';
}

sub fetch_id {
    my $dbd = shift;
    my($class, $dbh, $sth) = @_;
    $dbh->last_insert_id(undef, undef, undef, undef,
        { sequence => $dbd->sequence_name($class) });
}

1;
