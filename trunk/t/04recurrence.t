use strict;

use Test::More;
plan tests => 9;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# recurrence
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

my $res;

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = new DateTime::Set( dates => [ $t1, $t2 ] );

my $month_callback = sub {
            $_[0]->truncate( to => 'day' );
            # warn " truncate = ".$_[0]->ymd;
            $_[0]->add( months => 1 );
            # warn " add = ".$_[0]->ymd;
            return $_[0];
        };

# "START"
my $months = new DateTime::Set( 
    recurrence => $month_callback, 
    start => $t1,
);
$res = $months->min;
$res = $res->ymd if ref($res);
ok( $res eq '1810-09-01', 
    "min() - got $res" );
$res = $months->max;
$res = $res->ymd if ref($res);
ok( $res eq INFINITY,
    "max() - got $res" );

# "END"
my $months = new DateTime::Set(
    recurrence => $month_callback,
    end => $t1,
);
$res = $months->min;
$res = $res->ymd if ref($res);
ok( $res eq NEG_INFINITY,
    "min() - got $res" );
$res = $months->max;
$res = $res->ymd if ref($res);
ok( $res eq '1810-09-01',
    "max() - got $res" );

# "START+END"
my $months = new DateTime::Set(
    recurrence => $month_callback,
    start => $t1,
    end => $t2,
);
$res = $months->min;
$res = $res->ymd if ref($res);
ok( $res eq '1810-09-01',
    "min() - got $res" );
$res = $months->max;
$res = $res->ymd if ref($res);
ok( $res eq '1810-12-01',
    "max() - got $res" );


# "START+END" at recurrence 
$t1->set( day => 1 );  # month=8
$t2->set( day => 1 );  # month=11
my $months = new DateTime::Set(
    recurrence => $month_callback,
    start => $t1,
    end => $t2,
);
$res = $months->min;
$res = $res->ymd if ref($res);
ok( $res eq '1810-08-01',
    "min() - got $res" );
$res = $months->max;
$res = $res->ymd if ref($res);
ok( $res eq '1810-12-01',
    "max() - got $res" );


# verify that the set-span when backtracking is ok.
# This is _critical_ for doing correct intersections
$res = $months->intersection( DateTime->new( year=>1810, month=>12, day=>1 ) );
$res = $res->max;
$res = $res->ymd if ref($res);
ok( $res eq '1810-12-01',
    "intersection at the recurrence - got $res" );

1;

