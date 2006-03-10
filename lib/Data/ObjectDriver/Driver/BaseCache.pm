# $Id: BaseCache.pm 1141 2006-03-10 00:56:54Z btrott $

package Data::ObjectDriver::Driver::BaseCache;
use strict;
use base qw( Data::ObjectDriver Class::Accessor::Fast
             Class::Data::Inheritable );

use Carp ();

__PACKAGE__->mk_accessors(qw( cache fallback ));
__PACKAGE__->mk_classdata(qw( Disabled ));

sub init {
    my $driver = shift;
    $driver->SUPER::init(@_);
    my %param = @_;
    $driver->cache($param{cache})
        or Carp::croak("cache is required");
    $driver->fallback($param{fallback})
        or Carp::croak("fallback is required");
    $driver;
}

sub lookup {
    my $driver = shift;
    my($class, $id) = @_;
    return $driver->fallback->lookup($class, $id)
        if $driver->Disabled;
    my $key = $driver->cache_key($class, $id);
    my $obj = $driver->get_from_cache($key);
    unless ($obj) {
        $obj = $driver->fallback->lookup($class, $id);
        $driver->add_to_cache($key, $obj->clone_all) if $obj;
    }
    $obj;
}

sub get_multi_from_cache {
    my $driver = shift;
    my(@keys) = @_;
    ## Use driver->get_from_cache to look up each object in the cache.
    ## We don't fall back here, because we only want to find items that
    ## are already cached.
    my %got;
    for my $key (@keys) {
        my $obj = $driver->get_from_cache($key) or next;
        $got{$key} = $obj;
    }
    \%got;
}

sub lookup_multi {
    my $driver = shift;
    my($class, $ids) = @_;
    return $driver->fallback->lookup_multi($class, $ids)
        if $driver->Disabled;

    my %id2key = map { $_ => $driver->cache_key($class, $_) } @$ids;
    my $got = $driver->get_multi_from_cache(values %id2key);

    ## If we got back all of the objects from the cache, return immediately.
    if (scalar keys %$got == @$ids) {
        return [ map $got->{ $id2key{$_} }, @$ids ];
    }

    ## Otherwise, look through the list of IDs to see what we're missing,
    ## and fall back to the backend to look up those objects.
    my($i, @got, @need, %need2got) = (0);
    for my $id (@$ids) {
        if (my $obj = $got->{ $id2key{$id} }) {
            push @got, $obj;
        } else {
            push @got, undef;
            push @need, $id;
            $need2got{$#need} = $i;
        }
        $i++;
    }

    my $more = $driver->fallback->lookup_multi($class, \@need);
    $i = 0;
    for my $obj (@$more) {
        $got[ $need2got{$i++} ] = $obj;
        if ($obj) {
            my $id = $obj->primary_key_tuple;
            $driver->add_to_cache($driver->cache_key($class, $id),
                                  $obj->clone_all);
        }
    }

    \@got;
}

## We fallback by default
sub fetch_data { 
    my $driver = shift;
    my ($obj) = @_;
    return $driver->fallback->fetch_data($obj);
}

sub search {
    my $driver = shift;
    return $driver->fallback->search(@_)
        if $driver->Disabled;
    my($class, $terms, $args) = @_;

    ## If the caller has asked only for certain columns, assume that
    ## he knows what he's doing, and fall back to the backend.
    return $driver->fallback->search(@_)
        if $args->{fetchonly};

    ## Tell the fallback driver to fetch only the primary columns,
    ## then run the search using the fallback.
    $args->{fetchonly} = $class->primary_key_tuple; 
    ## Disable triggers for this load. We don't want the post_load trigger
    ## being called twice.
    $args->{no_triggers} = 1;
    my @objs = $driver->fallback->search($class, $terms, $args);

    ## Load all of the objects using a lookup_multi, which is fast from
    ## cache.
    my $objs = $driver->lookup_multi($class, [ map $_->primary_key, @objs ]);

    ## Now emulate the standard search behavior of returning an
    ## iterator in scalar context, and the full list in list context.
    if (wantarray) {
        return @$objs;
    } else {
        return sub { shift @$objs };
    }
}

sub update {
    my $driver = shift;
    my($obj) = @_;
    return $driver->fallback->update($obj)
        if $driver->Disabled;
    my $key = $driver->cache_key(ref($obj), $obj->primary_key);
    $driver->update_cache($key, $obj->clone_all);
    $driver->fallback->update($obj);
}

sub remove {
    my $driver = shift;
    my($obj) = @_;
    return $driver->fallback->remove($obj)
        if $driver->Disabled;
    $driver->remove_from_cache($driver->cache_key(ref($obj), $obj->primary_key));
    $driver->fallback->remove($obj);
}

sub cache_key {
    my $driver = shift;
    my($class, $id) = @_;
    join ':', $class, ref($id) eq 'ARRAY' ? @$id : $id;
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
    my $driver = $_[0];
    (my $meth = $AUTOLOAD) =~ s/.+:://;
    no strict 'refs';
    Carp::croak("Cannot call method '$meth' on object '$driver'")
        unless $driver->fallback->can($meth);
    *$AUTOLOAD = sub {
        shift->fallback->$meth(@_);
    };
    goto &$AUTOLOAD;
}

1;
