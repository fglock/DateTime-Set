use strict;

use Test::More;
plan tests => 3;

use DateTime;
use DateTime::Set;

#======================================================================
# BASIC INITIALIZATION TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = new DateTime::Set( $t1, $t2 );

ok( ($t1->ymd." and ".$t2->ymd) eq '1810-11-22 and 1900-11-22',
    "got 1810-11-22 and 1900-11-22 - DateTime" );


ok( $s1->min->ymd eq '1810-11-22', 
    'got 1810-11-22 - min' );

ok( $s1->max->ymd eq '1900-11-22',
    'got 1900-11-22 - max' );

1;

