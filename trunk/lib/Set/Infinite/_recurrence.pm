# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Set::Infinite::_recurrence;

use strict;

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

use vars qw( @ISA $PRETTY_PRINT $max_iterate );

@ISA = qw( Set::Infinite );
use Set::Infinite 0.5305;

BEGIN {
    $PRETTY_PRINT = 1;   # enable Set::Infinite debug
    $max_iterate = 20;

    # TODO: inherit %Set::Infinite::_first / _last 
    #       in a more "object oriented" way

    $Set::Infinite::_first{_recurrence} = 
        sub {
            my $self = $_[0];
            my ($callback_next, $callback_current, $callback_previous) = @{ $self->{param} };
            my ($min, $min_open) = $self->{parent}->min_a;

            # parameter correction for bounded recurrences
            $min = $callback_next->( DateTime::Infinite::Past->new ) unless ref( $min );

            if ( $min_open )
            {
                $min = $callback_next->( $min );
            }
            else
            {
                $min = $callback_current->( $min );
            }

            return ( $self->new( $min ),
                     $self->new( $callback_next->( $min ), 
                                 $self->{parent}->max )->
                          _function( '_recurrence', @{ $self->{param} } ) );
        };
    $Set::Infinite::_last{_recurrence} =
        sub {
            my $self = $_[0];
            my (undef, $callback_current, $callback_previous) = @{ $self->{param} };
            my ($max, $max_open) = $self->{parent}->max_a;

            # parameter correction for bounded recurrences
            $max = $callback_previous->( DateTime::Infinite::Future->new ) unless ref( $max );

            if ( $max_open )
            {
                $max = $callback_previous->( $max );
            }
            else
            {
                $max = $callback_current->( $max );
                $max = $callback_previous->( $max ) 
                    if $max > $self->{parent}->max;
            }

            return ( $self->new( $max ),
                     $self->new( $self->{parent}->min, 
                                 $callback_previous->( $max ) )->
                          _function( '_recurrence', @{ $self->{param} } ) );
        };
}

my $forever = Set::Infinite::_recurrence->new( NEG_INFINITY, INFINITY );

# $si->_recurrence(
#     \&callback_next, \&callback_current, \&callback_previous )
#
# Generates "recurrences" from a callback.
# These recurrences are simple lists of dates.
#
# The recurrence generation is based on an idea from Dave Rolsky.
#
sub _recurrence { 
    my $set = shift;
    my ( $callback_next, $callback_current, $callback_previous ) = @_;
    if ( $#{ $set->{list} } != 0 || $set->is_too_complex )
    {
        return $set->iterate( 
            sub { 
                $_[0]->_recurrence( 
                    $callback_next, $callback_current, $callback_previous ) 
            } );
    }
    # $set is a span
    my $result;
    if ($set->min != NEG_INFINITY && $set->max != INFINITY)
    {
        # print STDERR " finite set\n";
        my ($min, $min_open) = $set->min_a;
        my ($max, $max_open) = $set->max_a;
        if ( $min_open )
        {
            $min = $callback_next->( $min );
        }
        else
        {
            $min = $callback_current->( $min );
        }
        if ( $max_open )
        {
            $max = $callback_previous->( $max );
        }
        else
        {
            $max = $callback_current->( $max );
            $max = $callback_previous->( $max ) if $max > $set->max;
        }
        return $set->new( $min ) if $min == $max;
        $result = $set->new();
        for ( 1 .. 200 ) 
        {
            return $result if $min > $max;
            push @{ $result->{list} }, { a => $min, b => $min };
            $min = $callback_next->( $min );
        } 
        return $result if $min > $max;
        # warn "BIG set";
    }

    # return a "_function", such that we can backtrack later.
    my $func = $set->_function( '_recurrence', @_ );
    return $func->_function2( 'union', $result ) if $result;
    return $func;
}

sub is_forever
{
    $#{ $_[0]->{list} } == 0 &&
    $_[0]->max == INFINITY &&
    $_[0]->min == NEG_INFINITY
}

sub _is_recurrence 
{
    exists $_[0]->{method}           && 
    $_[0]->{method} eq '_recurrence' &&
    $_[0]->{parent}->is_forever
}

sub intersection
{
    my ($s1, $s2) = (shift,shift);

    if ( exists $s1->{method} && $s1->{method} eq '_recurrence' )
    {
        # optimize: recurrence && span
        return $s1->{parent}->
            intersection( $s2, @_ )->
            _recurrence( @{ $s1->{param} } )
                unless ref($s2) && exists $s2->{method};

        # optimize: recurrence && recurrence
        if ( $s1->{parent}->is_forever && 
            ref($s2) && _is_recurrence( $s2 ) )
        {
            my ( $next1, $current1, $previous1 ) = @{ $s1->{param} };
            my ( $next2, $current2, $previous2 ) = @{ $s2->{param} };
            return $s1->{parent}->_function( '_recurrence', 
                  sub {
                               # intersection of parent 'next' callbacks
                               my ($n1, $n2);
                               my $iterate = 0;
                               $n2 = $next2->( $_[0] );
                               while(1) { 
                                   $n1 = $current1->( $n2 );
                                   return $n1 if $n1 == $n2;
                                   $n2 = $current2->( $n1 );
                                   return if $iterate++ == $max_iterate;
                               }
                  },
                  sub {
                               # intersection of parent 'current' callbacks
                               my ($n1, $n2);
                               my $iterate = 0;
                               $n2 = $current2->( $_[0] );
                               while(1) {
                                   $n1 = $current1->( $n2 );
                                   return $n1 if $n1 == $n2;
                                   $n2 = $current2->( $n1 );
                                   return if $iterate++ == $max_iterate;
                               }
                  },
                  sub {
                               # intersection of parent 'previous' callbacks
                               my $arg = $_[0];
                               my ($tmp1, $p1, $p2);
                               my $iterate = 0;
                               while(1) { 
                                   $p1 = $previous1->( $arg );
                                   $p2 = $current2->( $p1 ); 
                                   return $p1 if $p1 == $p2;

                                   $p2 = $previous2->( $arg ); 
                                   $tmp1 = $current1->( $p2 ); 
                                   return $p2 if $p2 == $tmp1;

                                   $arg = $p1 < $p2 ? $p1 : $p2;
                                   return if $iterate++ == $max_iterate;
                               }
                  },
               );
        }
    }
    return $s1->SUPER::intersection( $s2, @_ );
}

sub union
{
    my ($s1, $s2) = (shift,shift);
    if ( $s1->_is_recurrence &&
         ref($s2) && _is_recurrence( $s2 ) )
    {
        # optimize: recurrence || recurrence
        my ( $next1, $current1, $previous1 ) = @{ $s1->{param} };
        my ( $next2, $current2, $previous2 ) = @{ $s2->{param} };
        return $s1->{parent}->_function( '_recurrence',
                  sub {  # next
                               my $n1 = $next1->( $_[0] );
                               my $n2 = $next2->( $_[0] );
                               return $n1 < $n2 ? $n1 : $n2;
                  },
                  sub {  # current
                               my $n1 = $current1->( $_[0] );
                               my $n2 = $current2->( $_[0] );
                               return $n1 < $n2 ? $n1 : $n2;
                  },
                  sub {  # previous
                               my $p1 = $previous1->( $_[0] );
                               my $p2 = $previous2->( $_[0] );
                               return $p1 > $p2 ? $p1 : $p2;
                  },
               );
    }
    return $s1->SUPER::union( $s2, @_ );
}

=head1 NAME

Set::Infinite::_recurrence - Extends Set::Infinite with recurrence functions

=head1 SYNOPSIS

    $recurrence = $base_set->_recurrence ( \&next, \&current, \&previous );

=head1 DESCRIPTION

This is an internal class used by the DateTime::Set module.
The API is subject to change.

It provides all functionality provided by Set::Infinite, plus the ability
to define recurrences with arbitrary objects, such as dates.

=head1 METHODS

=over 4

=item * _recurrence ( \&next, \&current, \&previous )

Creates a recurrence set. The set is defined inside a 'base set'.

   $recurrence = $base_set->_recurrence ( \&next, \&current, \&previous );

The recurrence functions take one argument, and return the 'next' or 
the 'previous' occurence. 
The C<current> function returns the 'next or equal' occurence.

Example: defines the set of all 'integer numbers':

    use strict;

    use Set::Infinite::_recurrence;
    use POSIX qw(floor);

    # define the recurrence span
    my $forever = Set::Infinite::_recurrence->new( 
        Set::Infinite::_recurrence::NEG_INFINITY, 
        Set::Infinite::_recurrence::INFINITY
    );

    my $recurrence = $forever->_recurrence(
        sub {   # next
                floor( $_[0] + 1 ) 
            },   
        sub {   # current
                floor( $_[0] ) 
            },       
        sub {   # previous
                my $tmp = floor( $_[0] ); 
                $tmp < $_[0] ? $tmp : $_[0] - 1
            },   
    );

    print "sample recurrence ",
          $recurrence->intersection( -5, 5 ), "\n";
    # sample recurrence -5,-4,-3,-2,-1,0,1,2,3,4,5

    {
        my $x = 234.567;
        print "next occurence after $x = ", 
              $recurrence->{param}[0]->( $x ), "\n";  # 235
        print "current occurence on $x = ",
              $recurrence->{param}[1]->( $x ), "\n";  # 234
        print "previous occurence before $x = ",
              $recurrence->{param}[2]->( $x ), "\n";  # 234
    }

    {
        my $x = 234;
        print "next occurence after $x = ",
              $recurrence->{param}[0]->( $x ), "\n";  # 235
        print "current occurence on $x = ",
              $recurrence->{param}[1]->( $x ), "\n";  # 234
        print "previous occurence before $x = ",
              $recurrence->{param}[2]->( $x ), "\n";  # 233
    }

=item * is_forever

Returns true if the set is a single span, 
ranging from -Infinity to Infinity.

=item * _is_recurrence

Returns true if the set is an unbounded recurrence, 
ranging from -Infinity to Infinity.

=back

=head1 CONSTANTS

=over 4

=item * INFINITY

The C<Infinity> value.

=item * NEG_INFINITY

The C<-Infinity> value.

=back

=head1 SUPPORT

Support is offered through the C<datetime@perl.org> mailing list.

Please report bugs using rt.cpan.org

=head1 AUTHOR

Flavio Soibelmann Glock <fglock@pucrs.br>

The recurrence generation algorithm is based on an idea from Dave Rolsky.

=head1 COPYRIGHT

Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
This program is free software; you can distribute it and/or
modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file
included with this module.

=head1 SEE ALSO

Set::Infinite

DateTime::Set

For details on the Perl DateTime Suite project please see
L<http://datetime.perl.org>.

=cut

