#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 2;

use DateTime;
use DateTime::Set;

#======================================================================
# TIME ZONE TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );


my $s2 = $s1->set_time_zone( 'Asia/Taipei' );

is( $s2->min->ymd, '1810-11-22', 
    'got 1811-11-22 - min' );

is( $s2->min->time_zone->name, 'Asia/Taipei', 
    'got time zone name from set' );

1;

