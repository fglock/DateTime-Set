package DateTime::Set::_cache;

use strict;
use Params::Validate qw( validate SCALAR BOOLEAN HASHREF OBJECT );
use vars qw( $validate $cache );

BEGIN {
    $cache = {};
    $validate = { 
        cache => {
                    can => 'set',  # Cache::Cache object
                    # default => undef,
                 },
        hash => {
                    type => HASHREF,
                    default => $cache,
                },
        key => {
                    type => SCALAR,
                    default => 'default',
               },
        };
}

# This is mostly a placeholder.
# The actual implementation is yet under discussion in datetime@perl.org

sub to_cache {
    my $self = shift;
    my $class = ref($self);
    die "Object must be a Set" unless UNIVERSAL::can( $self, 'union' );
    my %p = validate( @_, $validate );

    if ( $p{cache} ) 
    {
        # TODO!
        die "to_cache( cache => ) not implemented";
    }
    elsif ( $p{hash} 
    {
        $p{hash}{key} = $self->clone;
    }
    else
    {
        die "need a Cache object or a Hashref";
    }
    return $self;
}

sub from_cache {
    my $class = shift;
    my %p = validate( @_, $validate );
    my $self;

    if ( $p{cache} )
    {
        # TODO!
        die "from_cache( cache => ) not implemented";
    }
    elsif ( $p{hash}
    {
        unless ( exists ( $p{hash}{key} ) ) 
        {
            $p{hash}{key} = $class->empty_set;  # "auto-vivification"
        }
        $self = $p{hash}{key}->clone;
    }
    else
    {
        die "need a Cache object or a Hashref";
    }
    return $self;
}

# The cache() method must build an actual set-object,
# such that cacheing is transparent to the user.
#
# default cache is a simple in-memory hash
#
sub cache {
    my $self = shift;
    my $class = ref($self);
    die "Object must be a Set" unless UNIVERSAL::can( $self, 'union' );
    my %p = validate( @_, $validate );

    # TODO!
    die "not implemented";
}

1;

__END__

=head1 NAME

DateTime::Set::_cache.pm - An internal module to implement set cacheing 
through Cache::Cache API.

=head1 SYNOPSIS

  use DateTime::Set;

  $recurrence = DateTime::Set->from_recurrence( %args );
  $faster = $recurrence->cache;

=head1 DESCRIPTION

This module implements internal cacheing routines common to DateTime::Set 
and DateTime::SpanSet.

=head1 METHODS

=over 4 

=item * to_cache

Stores a set (non-recurrence) into a cache.

     $set->to_cache( cache => $cache, key => 'my_set' );

"key" is optional.

C<to_cache> will die if the set is a recurrence.

=item * from_cache

Retrieves a set (non-recurrence) from a cache.

     $set = DateTime::Set->from_cache( cache => $cache, key => 'my_set' );

"key" is optional.

C<from_cache> will die if the cached set is a recurrence.

=item * cache

Associates a cache to a recurrence set.

     $cached_set = $recurrence_set->cache( cache => $cache, key => 'my_set' );

"key" is optional.

=back

=head1 AUTHOR

Flavio S. Glock <fglock@pucrs.br>

=head1 COPYRIGHT

Copyright (c) 2003 Flavio S. Glock.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

Cache::Cache

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

