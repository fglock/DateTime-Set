use strict;

use Test::More;
plan tests => 3;

use DateTime;
use DateTime::Set;

#======================================================================
# SET ELEMENT IMMUTABILITY TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = new DateTime::Set( dates => [ $t1, $t2 ] );

ok( $s1->min->ymd eq '1810-11-22', 
    'got 1810-11-22 - min' );

$t1->add( days => 3 );

ok( $t1->ymd eq '1810-11-25',
    'change object to 1810-11-25' );

ok( $s1->min->ymd eq '1810-11-22',
    'still getting '. $s1->min->ymd . ' - after changing original object' );

1;

