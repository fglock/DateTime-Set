# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package DateTime::Set;

use strict;

use Params::Validate qw( validate SCALAR BOOLEAN OBJECT CODEREF ARRAYREF );
use Set::Infinite '0.44_04';
$Set::Infinite::PRETTY_PRINT = 1;   # enable Set::Infinite debug

use vars qw( @ISA $VERSION );

$VERSION = '0.00_17';

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);


# _add_callback( $set_infinite, $datetime_duration )
# Internal function
#
# Adds a value to a DateTime in a set.
#
# this is an internal callback - it is not an object method!
# Used by: add()
#
sub _add_callback {
    my $set = shift;   # $set is a Set::Infinite object
    my $dt = shift;    # $dt is a DateTime::Duration
    my $min = $set->min;
    if ( ref($min) ) {
        $min = $min->clone;
        $min->add_duration( $dt ) if ref($min);
    }
    my $result = $set->new( $min );
    return $result;
}; 

sub add {
    my ($self, %parm) = @_;
    my $dur;
    if (exists $parm{duration}) {
        $dur = $parm{duration}->clone;
    }
    else {
        $dur = new DateTime::Duration( %parm );
    }
    my $result = $self->{set}->iterate( \&_add_callback, $dur );

    ### this code would enable 'subroutine method' behaviour
    # $self->{set} = $result;
    # return $self;

    ### this code enables 'function method' behaviour
    my $set = $self->clone;
    $set->{set} = $result;
    return $set;
}

# note: the constructor must clone its DateTime parameters, such that
# the set elements become immutable
sub new {
    my $class = shift;
    my %args = validate( @_,
                         { start =>
                           { type => OBJECT,
                             optional => 1,
                           },
                           end =>
                           { type => OBJECT,
                             optional => 1,
                           },
                           recurrence =>
                           { type => CODEREF,
                             optional => 1,
                           },
                           dates => 
                           { type => ARRAYREF,
                             optional => 1,
                           },
                         }
                       );
    my $self = {};
    if (exists $args{dates}) {
        $self->{set} = Set::Infinite->new;
        # warn "new: inserting @{ $args{dates} }";
        for( @{ $args{dates} } ) {
            # warn "new: inserting ".$_->ymd;
            $self->{set} = $self->{set}->union( $_->clone );
        }
    }
    elsif (exists $args{recurrence}) {
        # Set::Infinity->iterate() builds a "set-function" with a callback:
        my $start = ( exists $args{start} ) ? $args{start} : NEG_INFINITY;
        my $end =   ( exists $args{end} )   ? $args{end}   : INFINITY;
        $start = $start->clone if ref($start);
        $end =   $end->clone   if ref($end);
        my $tmp_set = Set::Infinite->new( $start, $end );
        $self->{set} = _recurrence_callback( $tmp_set, $args{recurrence} );  
    }
    else {
        $self->{set} = Set::Infinite->new;
    }
    bless $self, $class;
    return $self;
}

sub clone { 
    bless { 
        set => $_[0]->{set}->copy,
        }, ref $_[0];
}

# _recurrence_callback( $set_infinite, \&callback )
# Internal function
#
# Generates "recurrences" from a callback.
# These recurrences are simple lists of dates.
#
# this is an internal callback - it is not an object method!
# Used by: new( recurrence => )
#
# The recurrence generation is based on an idea from Dave Rolsky.
#
sub _recurrence_callback {
    # warn "_recurrence args: @_";
    # note: $_[0] is a Set::Infinite object
    my ( $set, $callback ) = @_;    

    # test for the special case when we have an infinite recurrence

    if ($set->min == NEG_INFINITY ||
        $set->max == INFINITY) {

        return _setup_infinite_recurrence( $set, $callback );
    }
    else {

        return _setup_finite_recurrence( $set, $callback );
    }
}

sub _setup_infinite_recurrence {
    my ( $set, $callback ) = @_;

    # warn "_recurrence called with inf argument";
    return NEG_INFINITY if $set->min == NEG_INFINITY && $set->max == NEG_INFINITY;
    return INFINITY if $set->min == INFINITY && $set->max == INFINITY;
    # return an internal "_function", such that we can 
    # backtrack and solve the equation later.
    $set = $set->copy;
    my $func = $set->_function( 'iterate', 
        sub {
            _recurrence_callback( $_[0], $callback );
        }
    );

    # -- begin hack

    # This code will be removed, as soon as Set::Infinite can deal 
    # directly with this type of set generation.
    # Since this is a Set::Infinite "custom" function, the iterator 
    # will need some help.

    # Here we are setting up the first() cache directly,
    # because Set::Infinite has no hint of how to do it.
    if ($set->min == INFINITY || $set->min == NEG_INFINITY) {
        # warn "RECURR: start in ".$set->min;
        $func->{first} = [ $set->new( $set->min ), $set ];
    }
    else {
        my $min = $func->min;
        my $next = &$callback($min->clone);
        # warn "RECURR: preparing first: ".$min->ymd." ; ".$next->ymd;
        my $next_set = $set->intersection( $next->clone, INFINITY );
        # warn "next_set min is ".$next_set->min->ymd;
        my @first = ( 
            $set->new( $min->clone ), 
            $next_set->_function( 'iterate',
                sub {
                    _recurrence_callback( $_[0], $callback );
                } ) );
        # warn "RECURR: preparing first: $min ; $next; got @first";
        $func->{first} = \@first;
    }

    # Now are setting up the last() cache directly
    if ($set->max == INFINITY || $set->max == NEG_INFINITY) {
        # warn "RECURR: end in ".$set->max;
        $func->{last} = [ $set->new( $set->max ), $set ];
    }
    else {
        my $max = $func->max;
        # iterate to find previous value
        my $previous = _callback_previous( $max, $callback );
        # warn "previous: ".$previous->ymd;
        my $previous2 = _callback_previous( $previous, $callback );
        # my $previous3 = _callback_previous( $previous2, $callback );
        # warn "RECURR: preparing last: ".$previous2->ymd." ; ".$previous3->ymd;
        my $previous_set = $set->intersection( NEG_INFINITY, $previous2->clone );
        # warn "previous_set max is ".$previous_set->max->ymd;
        my @last = (
            $set->new( $max->clone ),
            $previous_set->_function( 'iterate',
                sub {
                    _recurrence_callback( $_[0], $callback );
                } ) );
        # warn "RECURR: preparing last: $max ; $previous; got @last";
        $func->{last} = \@last;
    }

    # -- end hack

    # warn "func parent is ". $func->{first}[1]{parent}{list}[0]{a}->ymd;
    return $func;
}

sub _setup_finite_recurrence {
    my ( $set, $callback ) = @_;

    # this is a finite recurrence - generate it.
    # warn "RECURR: FINITE recurrence";
    my $min = $set->min;
    return unless defined $min;

    $min = $min->clone->subtract( seconds => 1 );

    my $max = $set->max;
    # warn "_recurrence_callback called with ".$min->ymd."..".$max->ymd;
    my $result = $set->new;

    do {
        # warn " generate from ".$min->ymd;
        $min = &$callback( $min );
        # warn " generate got ".$min->ymd;
        $result = $result->union( $min->clone );
    } while ( $min <= $max );

    return $result;
}

# returns the "previous" value in a callback recurrence
sub _callback_previous {
    my ($value, $callback) = @_; 
    my $previous = $value->clone;
    # go back at least an year...
    # TODO: memoize.
    # TODO: binary search to find out what's the best subtract() unit.
    $previous->subtract( months => 13 );  
    # warn "current is ".$value->ymd." previous is ".$previous->ymd;
    $previous = &$callback( $previous );
    if ($previous >= $value) {
        die "_callback_previous iterator can't find a previous value, got ".$previous->ymd." before ".$value->ymd;
    }
    my $previous1;
    while (1) {
        $previous1 = $previous->clone;
        $previous = &$callback( $previous );
        return $previous1 if $previous >= $value;
    }
}

# iterator() doesn't do much yet.
# This might change as the API gets more complex.
sub iterator {
    return $_[0]->clone;
}

# next() gets the next element from an iterator()
sub next {
    my ($self) = shift;
    return undef unless ref( $self->{set} );
    my ($head, $tail) = $self->{set}->first;
    $self->{set} = $tail;
    return $head->min if defined $head;
    return $head;
}

# previous() gets the last element from an iterator()
sub previous {
    my ($self) = shift;
    return undef unless ref( $self->{set} );
    my ($head, $tail) = $self->{set}->last;
    $self->{set} = $tail;
    return $head->max if defined $head;
    return $head;
}

# Set::Infinite methods

sub intersection {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = $class->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    $tmp->{set} = $set1->{set}->intersection( $set2->{set} );
    return $tmp;
}

sub intersects {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = $class->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    return $set1->{set}->intersects( $set2->{set} );
}

sub contains {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = $class->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    return $set1->{set}->contains( $set2->{set} );
}

sub union {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = $class->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    $tmp->{set} = $set1->{set}->union( $set2->{set} );
    return $tmp;
}

sub complement {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    if (defined $set2) {
        $set2 = $class->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
        $tmp->{set} = $set1->{set}->complement( $set2->{set} );
    }
    else {
        $tmp->{set} = $set1->{set}->complement;
    }
    return $tmp;
}

sub min { 
    my $tmp = $_[0]->{set}->min;
    ref($tmp) ? $tmp->clone : $tmp; 
}

sub max { 
    my $tmp = $_[0]->{set}->max;
    ref($tmp) ? $tmp->clone : $tmp; 
}

# returns a DateTime::Span
sub span {
  my $set = $_[0]->{set}->span;
  bless $set, 'DateTime::Span';
  return $set;
}

# unsupported Set::Infinite methods

sub size { die "size() not supported - would be zero!"; }
sub offset { die "offset() not supported"; }
sub quantize { die "quantize() not supported"; }

1;

__END__

=head1 NAME

DateTime::Set - Date/time sets math

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Set;

    $date1 = DateTime->new( year => 2002, month => 3, day => 11 );
    $set1 = DateTime::Set->new( dates => [ $date1 ] );
    #  set1 = 2002-03-11

    $date2 = DateTime->new( year => 2003, month => 4, day => 12 );
    $set2 = DateTime::Set->new( dates => [ $date1, $date2 ] );
    #  set2 = 2002-03-11, and 2003-04-12

    # a 'monthly' recurrence:
    $set = DateTime::Set->new( 
        recurrence => sub {
            $_[0]->truncate( to => 'month' )->add( months => 1 )
        },
        start => $date1,    # optional
        end => $date2,      # optional
    );

    $set = $set1->union( $set2 );         # like "OR", "insert", "both"
    $set = $set1->complement( $set2 );    # like "delete", "remove"
    $set = $set1->intersection( $set2 );  # like "AND", "while"
    $set = $set1->complement;             # like "NOT", "negate", "invert"

    if ( $set1->intersects( $set2 ) ) { ...  # like "touches", "interferes"
    if ( $set1->contains( $set2 ) ) { ...    # like "is-fully-inside"

    # data extraction 
    $date = $set1->min;           # first date of the set
    $date = $set1->max;           # last date of the set

    $iter = $set1->iterator;
    while ( $dt = $iter->next ) {
        print $dt->ymd;
    };

=head1 DESCRIPTION

DateTime::Set is a module for date/time sets.  It can be used to
handle two different types of sets.

The first is a fixed set of predefined datetime objects.  For example,
if we wanted to create a set of dates containing the birthdays of
people in our family.

The second type of set that it can handle is one based on the idea of
a recurrence, such as "every Wednesday", or "noon on the 15th day of
every month".  This type of set can be have a fixed start and end
datetime, but neither is required.  So our "every Wednesday set" could
be "every Wednesday from the beginning of time until the end of time",
or "every Wednesday after 2003-03-05 until the end of time", or "every
Wednesday between 2003-03-05 and 2004-01-07".

=head1 METHODS

=over 4

=item * new

Creates a new set.  The set can either be a list of dates, or it can
be specified via a "recurrence" callback.

To create a set from a list of dates:

   $dates = DateTime::Set->new( dates => [ $dt1, $dt2, $dt3 ] );

To create a set as a recurrence:

    $months = DateTime::Set->new( 
        start => $today, 
        end => $today_plus_one_year,
        recurrence => sub { $_[0]->truncate( to => 'month' )->add( months => 1 ) }, 
    );

The "start" and "end" parameters are both optional.  If no "start"
parameter is given then the set is assumed to start at negative
infinity.  Similarly, if no "end" parameter is given then the set is
assumed to end at infinity.

=item * add

    $new_set = $set->add( year => 1 );

    $dtd = new DateTime::Duration( year => 1 );
    $new_set = $set->add( duration => $dtd );

This method returns a new set which is the same as the existing set
plus the specified duration.

    $meetings_2004 = $meetings_2003->add( years => 1 );

This method takes the same parameters as allowed by
C<DateTime->add()>.  It can also take a "duration" parameter, which
should be a C<DateTime::Duration> object.  If this parameter is given
then all others are ignored.

=item * min / max

First or last dates in the set.

=item * span

The total span of the set, as a DateTime::Span.

These methods can be used to iterate over the dates in a set.

    $iter = $set1->iterator;
    while ( $dt = $iter->next ) {
        print $dt->ymd;
    }

The C<next()> or C<previous()> return C<undef> when there are no 
more datetimes in the iterator.  

Obviously, if a set is specified as a recurrence and has no
fixed end datetime, then it may never stop returning datetimes.  User
beware!

=item union / intersection / complement

These set operations result in a DateTime::Set.

    $set = $set1->union( $set2 );         # like "OR", "insert", "both"
    $set = $set1->complement( $set2 );    # like "delete", "remove"
    $set = $set1->intersection( $set2 );  # like "AND", "while"
    $set = $set1->complement;             # like "NOT", "negate", "invert"

=item intersects / contains

These set operations result in a boolean value.

    if ( $set1->intersects( $set2 ) ) { ...  # like "touches", "interferes"
    if ( $set1->contains( $set2 ) ) { ...    # like "is-fully-inside"

=back

=head1 SUPPORT

Support is offered through the C<datetime@perl.org> mailing list.

Please report bugs using rt.cpan.org

=head1 AUTHOR

Flavio Soibelmann Glock <fglock@pucrs.br>

The API was developed together with Dave Rolsky and the DateTime Community.

=head1 COPYRIGHT

Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
This program is free software; you can distribute it and/or
modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file
included with this module.

=head1 SEE ALSO

Set::Infinite

L<http://datetime.perl.org>.

For details on the Perl DateTime Suite project please see
L<http://perl-date-time.sf.net>.

=cut

