#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 6;

use DateTime;
use DateTime::Set;

#======================================================================
# TIME ZONE TESTS
#====================================================================== 

my $t1 = new DateTime( year => '2001', month => '11', day => '22' );
my $t2 = new DateTime( year => '2002', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );


my $s2 = $s1->set_time_zone( 'Asia/Taipei' );

is( $s2->min->datetime, '2001-11-22T00:00:00', 
    'got 2001-11-22T00:00:00 - min' );

is( $s2->min->time_zone->name, 'Asia/Taipei', 
    'got time zone name from set' );

my $span1 = DateTime::Span->from_datetimes( start => $t1, end => $t2 );
$span1->set_time_zone( 'America/Sao_Paulo' );
my $span2 = $span1->clone;

$span1->set_time_zone( 'Asia/Taipei' );

is( $span1->start->datetime, '2001-11-22T10:00:00',
    'got 2001-11-22T10:00:00 - min' );
is( $span1->end->datetime, '2002-11-22T10:00:00',
    'got 2002-11-22T10:00:00 - max' );

# check for immutability
is( $span2->start->datetime, '2001-11-22T00:00:00',
    'got 2001-11-22T00:00:00 - min' );
is( $span2->end->datetime, '2002-11-22T00:00:00',
    'got 2002-11-22T00:00:00 - max' );

1;

