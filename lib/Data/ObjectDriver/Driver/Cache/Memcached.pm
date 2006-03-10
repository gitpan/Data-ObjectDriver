# $Id: Memcached.pm 1141 2006-03-10 00:56:54Z btrott $

package Data::ObjectDriver::Driver::Cache::Memcached;
use strict;
use base qw( Data::ObjectDriver::Driver::BaseCache );

use Cache::Memcached;
use Carp ();

sub add_to_cache            { shift->cache->add(@_)       }
sub update_cache            { shift->cache->set(@_)       }
sub remove_from_cache       { shift->cache->delete(@_)    }
sub get_from_cache          { shift->cache->get(@_)       }
sub get_multi_from_cache    { shift->cache->get_multi(@_) }

1;
