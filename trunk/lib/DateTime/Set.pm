# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package DateTime::Set;

use strict;

use Set::Infinite;

use vars qw( @ISA $VERSION );
@ISA = qw( Set::Infinite );

$VERSION = '0.00_03';

# declare our default 'leaf object' class
__PACKAGE__->type('DateTime');


1;

__END__

=head1 NAME

DateTime::Set - Date/time sets math

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Set;

    $date = DateTime->new( year => 2002, month => 3, day => 11 );
    $set = DateTime::Set->new( $date );

=head1 DESCRIPTION

DateTime::Set is a module for date/time sets. It allows you to generate
groups of dates, like "every wednesday", and then find all the dates
matching that pattern, within a time range.

This module is part of the perl-date-time project

It requires Set::Infinite.

=head1 METHODS

All methods are inherited from Set::Infinite.

=head1 NOTES

All set elements must be C<DateTime>.

A DateTime set may not contain scalars.

=head1 SUPPORT

Support will be offered through the C<datetime@perl.org> mailing list.

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

http://datetime.perl.org

=cut
