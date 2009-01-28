# $Id: Recipe.pm 506 2008-06-30 17:52:14Z ykerherve $

package Recipe;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;

__PACKAGE__->install_properties({
    columns => [ 'recipe_id', 'title' ],
    datasource => 'recipes',
    primary_key => 'recipe_id',
    driver => Data::ObjectDriver::Driver::DBI->new(
        dsn      => 'dbi:SQLite:dbname=global.db',
        reuse_dbh => 1,
    ),
});

1;
