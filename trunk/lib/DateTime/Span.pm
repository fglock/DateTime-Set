# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package DateTime::Span;

use strict;

use Params::Validate qw( validate SCALAR BOOLEAN OBJECT CODEREF ARRAYREF );
use Set::Infinite '0.44';
$Set::Infinite::PRETTY_PRINT = 1;   # enable Set::Infinite debug

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);


# note: the constructor must clone its DateTime parameters, such that
# the set elements become immutable
sub from_datetimes {
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
                           after =>
                           { type => OBJECT,
                             optional => 1,
                           },
                           before => 
                           { type => OBJECT,
                             optional => 1,
                           },
                         }
                       );
    my $self = {};
    my $set;
    unless ( grep { exists $args{$_} } qw( start end after before ) ) {
        die "No arguments given to DateTime::Span->new\n";
    }
    else {
        if ( exists $args{start} && exists $args{after} ) {
            die "Cannot give both start and after arguments to DateTime::Span->new\n";
        }
        if ( exists $args{end} && exists $args{before} ) {
            die "Cannot give both end and before arguments to DateTime::Span->new\n";
        }

        my ( $start, $open_start, $end, $open_end );
        ( $start, $open_start ) = ( NEG_INFINITY,  0 );
        ( $start, $open_start ) = ( $args{start},  0 ) if exists $args{start};
        ( $start, $open_start ) = ( $args{after},  1 ) if exists $args{after};
        ( $end,   $open_end   ) = ( INFINITY,      0 );
        ( $end,   $open_end   ) = ( $args{end},    0 ) if exists $args{end};
        ( $end,   $open_end   ) = ( $args{before}, 1 ) if exists $args{before};

        if ( $start > $end ) {
            die "Span cannot start after the end in DateTime::Span->new\n";
        }
        $set = Set::Infinite->new( $start, $end );
        if ( $start != $end ) {
            # remove start, such that we have ">" instead of ">="
            $set = $set->complement( $start ) if $open_start;  
            # remove end, such that we have "<" instead of "<="
            $set = $set->complement( $end )   if $open_end;    
        }
    }

    $self->{set} = $set;
    bless $self, $class;
    return $self;
}

sub from_datetime_and_duration {
    my $class = shift;
    my %args = @_;

    my $key;
    my $dt;
    # extract datetime parameters
    for ( qw( start end before after ) ) {
        if ( exists $args{$_} ) {
           $key = $_;
           $dt = delete $args{$_};
       }
    }

    # extract duration parameters
    my $dt_duration;
    if ( exists $args{duration} ) {
        $dt_duration = $args{duration};
    }
    else {
        $dt_duration = DateTime::Duration->new( %args );
    }
    # warn "Creating span from $key => ".$dt->datetime." and $dt_duration";
    my $other_date = $dt->clone->add_duration( $dt_duration );
    # warn "Creating span from $key => ".$dt->datetime." and ".$other_date->datetime;
    my $other_key;
    if ( $dt_duration->is_positive ) {
        # check if have to invert keys
        $key = 'after' if $key eq 'end';
        $key = 'start' if $key eq 'before';
        $other_key = 'before';
    }
    else {
        # check if have to invert keys
        $other_key = 'end' if $key eq 'after';
        $other_key = 'before' if $key eq 'start';
        $key = 'start';
    }
    return $class->new( $key => $dt, $other_key => $other_date ); 
}

# This method is intentionally not documented.  It's really only for
# use by ::Set and ::SpanSet's as_list() and iterator() methods.
sub new {
    my $class = shift;
    my %args = @_;

    # If we find anything _not_ appropriate for from_datetimes, we
    # assume it must be for durations, and call this constructor.
    # This way, we don't need to hardcode the DateTime::Duration
    # parameters.
    foreach ( keys %args )
    {
        return $class->from_datetime_and_duration(%args)
            unless /^(?:before|after|start|end)$/;
    }

    return $class->from_datetimes(%args);
}

sub clone { 
    bless { 
        set => $_[0]->{set}->copy,
        }, ref $_[0];
}

# Set::Infinite methods

sub intersection {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = DateTime::Set->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    $tmp->{set} = $set1->{set}->intersection( $set2->{set} );

    # intersection() can generate something more complex than a span.
    bless $tmp, 'DateTime::SpanSet';

    return $tmp;
}

sub intersects {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = DateTime::Set->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    return $set1->{set}->intersects( $set2->{set} );
}

sub contains {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = DateTime::Set->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    return $set1->{set}->contains( $set2->{set} );
}

sub union {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    $set2 = DateTime::Set->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
    $tmp->{set} = $set1->{set}->union( $set2->{set} );
 
    # union() can generate something more complex than a span.
    bless $tmp, 'DateTime::SpanSet';

    # # We have to check it's internal structure to find out.
    # if ( $#{ $tmp->{set}->{list} } != 0 ) {
    #    bless $tmp, 'Date::SpanSet';
    # }

    return $tmp;
}

sub complement {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = {};   # $class->new;
    if (defined $set2) {
        $set2 = DateTime::Set->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
        $tmp->{set} = $set1->{set}->complement( $set2->{set} );
    }
    else {
        $tmp->{set} = $set1->{set}->complement;
    }

    # complement() can generate something more complex than a span.
    bless $tmp, 'DateTime::SpanSet';

    # # We have to check it's internal structure to find out.
    # if ( $#{ $tmp->{set}->{list} } != 0 ) {
    #    bless $tmp, 'Date::SpanSet';
    # }

    return $tmp;
}

sub start { 
    my $tmp = $_[0]->{set}->min;
    ref($tmp) ? $tmp->clone : $tmp; 
}

*min = \&start;

sub end { 
    my $tmp = $_[0]->{set}->max;
    ref($tmp) ? $tmp->clone : $tmp; 
}

*max = \&end;

sub start_is_open {
    # min_a returns info about the set boundary 
    my ($min, $open) = $_[0]->{set}->min_a;
    return $open;
}

sub start_is_closed { $_[0]->start_is_open ? 0 : 1 }

sub end_is_open {
    # max_a returns info about the set boundary 
    my ($max, $open) = $_[0]->{set}->max_a;
    return $open;
}

sub end_is_closed { $_[0]->end_is_open ? 0 : 1 }


# span == $self
sub span { @_ }

sub duration { my $dur = $_[0]->end - $_[0]->start; defined $dur ? $dur : INFINITY }
*size = \&duration;

# unsupported Set::Infinite methods

sub offset { die "offset() not supported"; }
sub quantize { die "quantize() not supported"; }

1;

__END__

=head1 NAME

DateTime::Span - Datetime spans

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Span;

    $date1 = DateTime->new( year => 2002, month => 3, day => 11 );
    $date2 = DateTime->new( year => 2003, month => 4, day => 12 );
    $set2 = DateTime::Span->from_datetimes( start => $date1, end => $date2 );
    #  set2 = 2002-03-11 until 2003-04-12

    $set = $set1->union( $set2 );         # like "OR", "insert", "both"
    $set = $set1->complement( $set2 );    # like "delete", "remove"
    $set = $set1->intersection( $set2 );  # like "AND", "while"
    $set = $set1->complement;             # like "NOT", "negate", "invert"

    if ( $set1->intersects( $set2 ) ) { ...  # like "touches", "interferes"
    if ( $set1->contains( $set2 ) ) { ...    # like "is-fully-inside"

    # data extraction 
    $date = $set1->start;           # first date of the span
    $date = $set1->end;             # last date of the span

=head1 DESCRIPTION

DateTime::Span is a module for date/time spans or time-ranges. 

=head1 METHODS

=over 4

=item * from_datetimes

Creates a new span based on a starting and ending datetime.

A 'closed' span includes its end-dates:

   $span = DateTime::Span->from_datetimes( start => $dt1, end => $dt2 );

An 'open' span does not include its end-dates:

   $span = DateTime::Span->from_datetimes( after => $dt1, before => $dt2 );

A 'semi-open' span includes one of its end-dates:

   $span = DateTime::Span->from_datetimes( start => $dt1, before => $dt2 );
   $span = DateTime::Span->from_datetimes( after => $dt1, end => $dt2 );

A span might have just a beginning date, or just an ending date.
These spans end, or start, in an imaginary 'forever' date:

   $span = DateTime::Span->from_datetimes( start => $dt1 );
   $span = DateTime::Span->from_datetimes( end => $dt2 );
   $span = DateTime::Span->from_datetimes( after => $dt1 );
   $span = DateTime::Span->from_datetimes( before => $dt2 );

You cannot give both a "start" and "after" argument, nor can you give
both an "end" and "before" argument.  Either of these conditions cause
will cause the C<from_datetimes()> method to die.

=item * from_datetime_and_duration

Creates a new span.

   $span = DateTime::Span->from_datetime_and_duration( 
       start => $dt1, duration => $dt_dur1 );
   $span = DateTime::Span->from_datetime_and_duration( 
       after => $dt1, hours => 12 );

The new "end of the set" is I<open> by default.

=item * duration

The total size of the set, as a C<DateTime::Duration> object, or as a
scalar containing infinity.

Also available as C<size()>.

=item * start / end

First or last dates in the span.  It is possible that the return value
from these methods may be a scalar containing either negative infinity
or positive infinity.

=item * start_is_closed / end_is_closed

Returns true if the first or last dates belong to the span ( begin <= x <= end ).

=item * start_is_open / end_is_open

Returns true if the first or last dates are excluded from the span ( begin < x < end ).

=item * union / intersection / complement

Set operations may be performed not only with C<DateTime::Span>
objects, but also with C<DateTime::Set> and C<DateTime::SpanSet>
objects.  These set operations always return a C<DateTime::SpanSet>
object.

    $set = $span->union( $set2 );         # like "OR", "insert", "both"
    $set = $span->complement( $set2 );    # like "delete", "remove"
    $set = $span->intersection( $set2 );  # like "AND", "while"
    $set = $span->complement;             # like "NOT", "negate", "invert"

=item intersects / contains

These set functions return a boolean value.

    if ( $span->intersects( $set2 ) ) { ...  # like "touches", "interferes"
    if ( $span->contains( $dt ) ) { ...    # like "is-fully-inside"

These methods can accept a C<DateTime>, C<DateTime::Set>,
C<DateTime::Span>, or C<DateTime::SpanSet> object as an argument.

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

For details on the Perl DateTime Suite project please see
L<http://datetime.perl.org>.

=cut

