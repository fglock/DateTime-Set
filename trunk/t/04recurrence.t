use strict;

use Test::More;
plan tests => 4;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# create_recurrence() TESTS
#====================================================================== 

my $res;

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = new DateTime::Set( $t1, $t2 );

my $months = $s1->create_recurrence( time_unit => 'months' );

$res = $months->min->ymd;
ok( $res eq '1810-08-01', 
    "min() - got $res" );

$res = $months->first->max->ymd;
ok( $res eq '1810-08-01',
    "month results are 'scalars', not 'intervals' - got $res" );

my $all_months = DateTime::Set->create_recurrence( time_unit => 'months' );  
my $month_day_1 = $all_months->add_duration( 
    at_start => DateTime::Duration->new( days => 0 ), 
    at_end =>   DateTime::Duration->new( days => 1 ) );
my $my_months = $s1->intersection( $month_day_1 );

$res = $my_months->min->ymd;
ok( $res eq '1810-09-01',
    "min, too_complex - got $res" );

$res = $my_months->first->max->ymd;
ok( $res eq '1810-09-02',
    "first - got $res" );

1;

