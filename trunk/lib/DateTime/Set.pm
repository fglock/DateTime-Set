# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package DateTime::Set;

use strict;

use Set::Infinite;
use DateTime::Duration;

use vars qw( @ISA $VERSION );
@ISA = qw( Set::Infinite );

$VERSION = '0.00_07';

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

# declare our default 'leaf object' class
### __PACKAGE__->type('DateTime');

# warn about Set::Infinite methods that don't work here
# because they use 'epoch' values internally
#
sub quantize { die "quantize() method is not supported. Please use create_recurrence instead." }
sub offset   { die "offset() method is not supported. Please use add_duration() instead." }

my %set =
    ( years =>
      { month => 1, day => 1, hour => 0, minute => 0, second => 0 },

      months =>
      { day => 1, hour => 0, minute => 0, second => 0 },

      days =>
      { hour => 0, minute => 0, second => 0 },

      hours =>
      { minute => 0, second => 0 },

      minutes =>
      { second => 0 },
    );

# generates simple recurrences of "months", "hours", etc.
sub create_recurrence {
    my $self = shift;
    my %parm = validate( @_,
                         { time_unit =>
                           { type => SCALAR,
                             regex => qr/^years|months|days|hours|minutes|seconds$/,
                           },
                         }
                       );

    # $parm{interval} = 1 unless $parm{interval};

    unless (ref $self) {
        $self = __PACKAGE__->new( NEG_INFINITY, INFINITY );
    }
    if ($self->is_too_complex ||
        $self->min == NEG_INFINITY ||
        $self->max == INFINITY ) {
        return $self if $self->min == $self->max;  # it is a single inf value
        return $self->_function( 'create_recurrence', %parm );
    }

    my $this = $self->min;
    my $max = $self->max;
    my $duration = new DateTime::Duration( $parm{time_unit} => 1 );

    # round the start time according to the time_unit
    $this->set( %{ $set{ $parm{time_unit} } )

    # $this->set(  ) if $parm{time_unit} eq 'seconds';
    if ($parm{time_unit} eq 'weeks') {
        my $dow = $this->day_of_week - 1;  # 0 is monday
        $this->subtract( days => $dow );
        $this->set( %{ $set{weeks} } );
    }

    my $result = $self->new->no_cleanup;
    my $prev;
    my $subset;
    while ( $this <= $max ) {
        #### NOTE: comment this out to enable 'full-period' semantics
        ## $prev = $this->clone;
        ## $this->add_duration( $duration );
        ## $subset = $self->new( $prev, $this );
        ## $subset = $subset->complement( $this ) unless $prev == $this; # open-end
        #### END NOTE

        # 'begin-of-period' semantics - This seems to be more like what rfc2445 expects
        $subset = $self->new( $this, $this );  # don't use new($this) - it will clone $this just once.
        $this->add_duration( $duration );

        ## note: this wouldn't work here: $result = $result->union( $subset ); 
        push @{$result->{list}}, $subset->{list}[0] if exists $subset->{list}[0];
    }

    return $result;
}

# quantization methods must register with _quantize_span()
#
sub _quantize_span {
    my $self = shift;
    my %param = @_;
    if ($self->{too_complex} &&
        $self->{method} eq 'create_recurrence') {
        my $res = $self->{parent};
        if ($res->{too_complex}) {
            $res = $res->_quantize_span( %param );
            $res = $res->create_recurrence->_quantize_span( %param );
            return $res;
        }
        return $self;
    }
    return $self->SUPER::_quantize_span( %param );
}

# add_duration provides more-or-less the same functionality 
# as Set::Infinite::offset(), without the 'epoch' limitations
#
sub add_duration { 
    my ($self, %parm) = @_;

    #### Uncomment this line if it is possible that 'durations' are mutable; we assume they are immutable.
    ## $parm{$_} = $parm{$_}->clone for keys %parm;
    ####

    my $result = $self->iterate( 
        sub {
            my $set = shift;
            my ($min, $open_start) = $set->min_a;
            my ($max, $open_end)   = $set->max_a;
            $min->add_duration( $parm{at_start} ) if exists $parm{at_start};
            $max->add_duration( $parm{at_end} )   if exists $parm{at_end};
            return if $min > $max;
            my $res = $set->new( $min, $max );
            if ( $open_start ) {
                $res = $res->complement( $min ) unless $min == $max;  # open_start
            }
            if ( $open_end ) {
                $res = $res->complement( $max ) unless $min == $max;  # open_end
            }
            return $res;
        }
    );
    return $result;
}

# the constructor must clone its DateTime parameters, so that
# the set elements become (more-or-less) immutable
sub new {
    my $class = shift;
    my @parm = @_;
    for (0..$#parm) {
        $parm[$_] = $parm[$_]->clone if UNIVERSAL::isa( $parm[$_], 'DateTime' );  
    } 
    $class->SUPER::new( @parm );
}

# min / max return clones, such that the program can't change
# our set through the values returned.
sub min {
    my $val = $_[0]->SUPER::min;
    return $val->clone if UNIVERSAL::isa( $val, 'DateTime' );
    return $val;
}

sub max {
    my $val = $_[0]->SUPER::max;
    return $val->clone if UNIVERSAL::isa( $val, 'DateTime' );
    return $val;
}

1;

__END__

=head1 NAME

DateTime::Set - Date/time sets math

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Set;

    $date1 = DateTime->new( year => 2002, month => 3, day => 11 );
    $set1 = DateTime::Set->new( $date1 );
    #  set1 = 2002-03-11

    $date2 = DateTime->new( year => 2003, month => 4, day => 12 );
    $set2 = DateTime::Set->new( $date1, $date2 );
    #  set2 = since 2002-03-11, until 2003-04-12

    $set = $set1->union( $set2 );         # like "OR", "insert", "both"
    $set = $set1->complement( $set2 );    # like "delete", "remove"
    $set = $set1->intersection( $set2 );  # like "AND", "while"
    $set = $set1->complement;             # like "NOT", "negate", "invert"

    if ( $set1->intersects( $set2 ) ) { ...  # like "touches", "interferes"
    if ( $set1->contains( $set2 ) ) { ...    # like "is-fully-inside"

    # data extraction 
    $date = $set1->min;           # start date
    $date = $set1->max;           # end date
    # disjunct sets can be split into an array of simpler sets
    @subsets = $set1->list;
    $date = $subsets[1]->min;

=head1 DESCRIPTION

DateTime::Set is a module for date/time sets. It allows you to generate
groups of dates, like "every wednesday", and then find all the dates
matching that pattern, within a time range.

=head1 ERROR HANDLING

A method will return C<undef> if it can't find a suitable 
representation for its result, such as when trying to 
C<list()> a too complex set.

Programs that expect to generate empty sets or complex sets
should check for the C<undef> return value when extracting data.

Set elements must be either a C<DateTime> or a C<+/- Infinity> value.
Scalar values, including date strings, are not expected and
might cause strange results.

=head1 METHODS

All methods are inherited from Set::Infinite.

Set::Infinite methods C<offset()> and C<quantize()> are disabled.
The module will die with an error string if one of these methods are 
called.

=head2 New Methods

=over 4

=item * add_duration

NOTE: this is an experimental feature.

    add_duration( at_start => $datetime_duration, 
                  at_end =>   $datetime_duration );

This method returns a new set, which is created by adding a 
C<DateTime::Duration> to the current datetime set.

It moves the whole set values ahead or back in time.
It will affect the start, end, or both ends of the set intervals.

Example:

    $one_year = DateTime::Duration( years => 1 );
    $meetings_2004 = $meetings_2003->add_duration( 
         at_start => $one_year,
         at_end   => $one_year );

=item * create_recurrence 

NOTE: this is an experimental feature.

Generates recurrence intervals of "years", "months", "weeks", "days",
"hours", "minutes", or "seconds".

    $months = DateTime::Set->create_recurrence( time_unit => 'months' );

Recurrences can be filtered and combined, in order to build more
complex recurrences.

Example:

    $weeks = DateTime::Set->create_recurrence( time_unit => 'weeks' );
    $one_day =  DateTime::Duration( days => 1 );
    $two_days = DateTime::Duration( days => 2 );

    $tuesdays = $weeks->add_duration(
         at_start => $one_day,           # +24h from week start
         at_end   => $two_days );        # +48h from week start

=back

=head1 SUPPORT

Support is offered through the C<datetime@perl.org> mailing list.

Please report bugs using rt.cpan.org

=head1 AUTHOR

Flavio Soibelmann Glock <fglock@pucrs.br>

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

