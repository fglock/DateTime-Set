use strict;

use Test::More;
plan tests => 2;

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
            $_[0]->truncate( to => 'month' );
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


my $iterator = $months->iterator;
my @res;
TODO: {
    local $TODO = "Set::Infinite gives deep-recursion";
    for (1..3) {
        #### push @res, $iterator->next->ymd;
    }
    $res = join( ' ', @res );
    ok( $res eq ' ',
        "3 iterations give $res" );
}

1;

