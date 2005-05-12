#!/usr/bin/perl

# this test was contributed by Stephen Gowing

use strict;

use Test::More tests => 2;

use DateTime;
use DateTime::Set;

my $d1 = DateTime->new( year => 2002, month => 3, day => 11 );
my $d2 = DateTime->new( year => 2002, month => 4, day => 11 );
my $d3 = DateTime->new( year => 2002, month => 5, day => 11 );
my( $set, $r, @dt );

$set = DateTime::Set->from_datetimes( dates => [ $d1 ] );
@dt = $set->as_list;
$r = join(' ', @dt);

is($r, '2002-03-11T00:00:00', 'Single date set');

@dt = $set->as_list( start => $d2, end => $d3 );
$r = join(' ', @dt);

is($r, '', 'Out of range');
