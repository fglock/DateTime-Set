# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package DateTime::Set;

use strict;
use Carp;
use Set::Infinite;

use vars qw( @ISA $VERSION );
@ISA = qw( Set::Infinite );

$VERSION = '0.00_06';

# declare our default 'leaf object' class
__PACKAGE__->type('DateTime');

# warn about Set::Infinite methods that don't work here
# because they use 'epoch' values internally
#
sub quantize { die "quantize() method is not supported." }
sub offset   { die "offset() method is not supported. Please use add_duration() instead." }

# add_duration provides more-or-less the same functionality 
# as Set::Infinite::offset()
#
sub add_duration { 
    my ($self, %parm) = @_;
    my $result = $self->iterate( 
        sub {
            my $set = shift;
            my ($min, $open_start) = $set->min;
            my ($max, $open_end)   = $set->max;
            $min->add_duration( $parm{at_start} ) if exists $parm{at_start};
            $max->add_duration( $parm{at_end} )   if exists $parm{at_end};
            return if $min > $max;
            my $res = $set->new( $min, $max );
            if ( $open_start ) {
                $res = $res->complement( $min );  # open_start
            }
            if ( $open_end ) {
                $res = $res->complement( $max );  # open_end
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

=over 4

=item * add_duration

NOTE: this is an experimental feature.

    add_duration( at_start => $datetime_duration, 
                  at_end =>   $datetime_duration );

This method returns a new set, which is created by adding a 
C<DateTime::Duration> to the current datetime set.

It moves the whole set values ahead or back in time.
It will affect the start, end, or both ends of the set intervals.

    $mondays = $sundays->add_duration( 
         at_start => $one_day,
         at_end   => $one_day );

    $mondays_and_tuesdays = $sundays->add_duration(
         at_start => $one_day,
         at_end   => $two_days );

This method provides more-or-less the same functionality as
C<Set::Infinite::offset()>.

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

