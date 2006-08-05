# $Id: ErrorTest.pm 210 2006-05-23 18:58:57Z btrott $

package ErrorTest;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;

__PACKAGE__->install_properties({
    columns => [ 'foo' ],
    datasource => 'error_test',
    primary_key =>  [ ],
    driver => Data::ObjectDriver::Driver::DBI->new(
        dsn      => 'dbi:SQLite:dbname=global.db',
    ),
});
