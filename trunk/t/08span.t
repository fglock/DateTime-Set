use strict;

use Test::More;
plan tests => 2;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# SPAN TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = DateTime::Span->from_datetime_and_duration( start => $t1, hours => 2 );

my $res = $s1->min->ymd.'T'.$s1->min->hms;
ok( $res eq '1810-11-22T00:00:00',
    "got $res - min" );
$res = $s1->max->ymd.'T'.$s1->max->hms;
ok( $res eq '1810-11-22T02:00:00',
    "got $res - max" );

1;

