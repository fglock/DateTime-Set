use strict;

use Test::More;
plan tests => 3;

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
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

my $month_callback = sub {
            $_[0]->truncate( to => 'month' )
                 ->add( months => 1 );
        };


# "START"
my $months = DateTime::Set->from_recurrence( 
    recurrence => $month_callback, 
    start => $t1,
);
$res = $months->min;
$res = $res->ymd if ref($res);
ok( $res eq '1810-09-01', 
    "min() - got $res" );


my $iterator = $months->iterator;
my @res;
for (1..3) {
        my $tmp = $iterator->next;
        push @res, $tmp->ymd if defined $tmp;
}
$res = join( ' ', @res );
ok( $res eq '1810-09-01 1810-10-01 1810-11-01',
        "3 iterations give $res" );


# sub-second iterator
{
    my $count = 0;
    my $micro_callback = sub {
            # truncate and add to 'microsecond'
            $_[0]->set( nanosecond =>
                           1000 * int( $_[0]->nanosecond / 1000 ) )
                 ->add( nanoseconds => 1000 );
            # warn "nanosec = ".$_[0]->datetime.'.'.sprintf('%06d',$_[0]->microsecond);

            # guard against an infinite loop error
            return INFINITY if $count++ > 20;  

            return $_[0];
    };
    my $microsec = DateTime::Set->from_recurrence(
        recurrence => $micro_callback,
        start => $t1,
    );
    my $iterator = $microsec->iterator;
    my @res;
    for (1..3) {
        my $tmp = $iterator->next;
        if (defined $tmp) {
            my $str = $tmp->datetime.'.'.sprintf('%06d',$tmp->microsecond);
            # warn "iter: $str";
            push @res, $str;
        }
    }

    $res = join( ' ', @res );
    ok( $res eq '1810-08-22T00:00:00.000000 1810-08-22T00:00:00.000001 1810-08-22T00:00:00.000002',
        "3 iterations give $res" );
}

1;

