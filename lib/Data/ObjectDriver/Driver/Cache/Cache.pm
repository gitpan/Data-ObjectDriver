# $Id: Cache.pm 169 2006-05-04 00:15:55Z sky $

package Data::ObjectDriver::Driver::Cache::Cache;
use strict;
use warnings;

use base qw( Data::ObjectDriver::Driver::BaseCache );

sub get_from_cache    { shift->cache->thaw(@_)   }
sub add_to_cache      { shift->cache->freeze(@_) }
sub update_cache      { shift->cache->freeze(@_) }
sub remove_from_cache { shift->cache->remove(@_) }

1;
