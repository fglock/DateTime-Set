# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package DateTime::Span;

use strict;

use Params::Validate qw( validate SCALAR BOOLEAN OBJECT CODEREF ARRAYREF );
use Set::Infinite '0.44';
$Set::Infinite::PRETTY_PRINT = 1;   # enable Set::Infinite debug

use vars qw( @ISA $VERSION );

# $VERSION = '0.00_13';

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);


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
        my $set = Set::Infinite->new( $start, $end );
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
    bless $tmp, 'Date::SpanSet';

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
    bless $tmp, 'Date::SpanSet';

    # # We have to check it's internal structure to find out.
    # if ( $#{ $tmp->{set}->{list} } != 0 ) {
    #    bless $tmp, 'Date::SpanSet';
    # }

    return $tmp;
}

sub complement {
    my ($set1, $set2) = @_;
    my $class = ref($set1);
    my $tmp = $class->new();
    if (defined $set2) {
        $set2 = DateTime::Set->new( dates => [ $set2 ] ) unless $set2->can( 'union' );
        $tmp->{set} = $set1->{set}->complement( $set2->{set} );
    }
    else {
        $tmp->{set} = $set1->{set}->complement;
    }

    # complement() can generate something more complex than a span.
    bless $tmp, 'Date::SpanSet';

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

sub end { 
    my $tmp = $_[0]->{set}->max;
    ref($tmp) ? $tmp->clone : $tmp; 
}

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

sub duration { return $_[0]->{set}->size; }

# unsupported Set::Infinite methods

sub offset { die "offset() not supported"; }
sub quantize { die "quantize() not supported"; }

1;

__END__

=head1 NAME

DateTime::Span - Date/time spans

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Span;

    $date1 = DateTime->new( year => 2002, month => 3, day => 11 );
    $date2 = DateTime->new( year => 2003, month => 4, day => 12 );
    $set2 = DateTime::Span->new( start => $date1, end => $date2 );
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

=item * new 

Generates a new span. 

A 'closed' span includes its end-dates:

   $dates = DateTime::Set->new( start => $dt1, end => $dt2 );

An 'open' span does not include its end-dates:

   $dates = DateTime::Set->new( after => $dt1, before => $dt2 );

A 'semi-open' span includes one of its end-dates:

   $dates = DateTime::Set->new( start => $dt1, before => $dt2 );
   $dates = DateTime::Set->new( after => $dt1, end => $dt2 );

A span might have just a begin date, or just an end date. 
These spans end, or start, in an imaginary 'forever' date:

   $dates = DateTime::Set->new( start => $dt1 );
   $dates = DateTime::Set->new( end => $dt2 );
   $dates = DateTime::Set->new( after => $dt1 );
   $dates = DateTime::Set->new( before => $dt2 );

You cannot give both a "start" and "after" argument, nor can you give
both an "end" and "before" argument.  Either of these conditions cause
will cause the C<new()> method to die.

=back

=item * duration

Return a DateTime::Duration object that represents the length of the
span.

=item * start / end

First or last dates in the span.

=item * start_is_closed / end_is_closed

Return true if the first or last dates belong to the span ( begin <= x <= end ).

=item * start_is_open / end_is_open

Return true if the first or last dates are out of the span ( begin < x < end ).

=item * duration

The duration of the span, as a DateTime::Duration.

This is the sum of the durations of all spans.

=item * union / intersection / complement

These set operations result in a DateTime::SpanSet.

    $set = $set1->union( $set2 );         # like "OR", "insert", "both"
    $set = $set1->complement( $set2 );    # like "delete", "remove"
    $set = $set1->intersection( $set2 );  # like "AND", "while"
    $set = $set1->complement;             # like "NOT", "negate", "invert"

=item intersects / contains

These set functions result in a boolean value.

    if ( $set1->intersects( $set2 ) ) { ...  # like "touches", "interferes"
    if ( $set1->contains( $set2 ) ) { ...    # like "is-fully-inside"

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

