package DateTime::Set::_cache;

use strict;

# blah blah blah
# the actual implementation is yet under discussion in datetime@perl.org

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

=head1 AUTHOR

Flavio S. Glock <fglock@pucrs.br>

=head1 COPYRIGHT

Copyright (c) 2003 Flavio S. Glock.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

