use strict;

use Test::More;
plan tests => 1;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# ADD_DURATION ("OFFSET") TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = new DateTime::Set( $t1, $t2 );

my $dur1 = new DateTime::Duration ( years => 1 );
my $s2 = $s1->add_duration( at_start => $dur1 );

ok( $s2->min->ymd eq '1811-11-22', 
    'got 1811-11-22 - min' );

1;

