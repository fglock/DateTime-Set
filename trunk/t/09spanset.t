use strict;

use Test::More;
plan tests => 13;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::SpanSet;

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

sub str { ref($_[0]) ? $_[0]->datetime : $_[0] }

#======================================================================
# SPANSET TESTS
#====================================================================== 

my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
my $end1   = new DateTime( year => '1811', month => '10', day => '21' );
my $start2 = new DateTime( year => '1812', month => '11', day => '22' );
my $end2   = new DateTime( year => '1813', month => '12', day => '23' );

my $start_set = DateTime::Set->from_datetimes( dates => [ $start1, $start2 ] );
my $end_set   = DateTime::Set->from_datetimes( dates => [ $end1, $end2 ] );

my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );

my $iter = $s1->iterator;

my $res = $iter->next;
$res = $res->min->datetime . ".." . $res->max->datetime;
ok( $res eq '1810-09-20T00:00:00..1811-10-21T00:00:00',
    "got $res" );

my $res = $iter->next;
$res = $res->min->datetime . ".." . $res->max->datetime;
ok( $res eq '1812-11-22T00:00:00..1813-12-23T00:00:00',
    "got $res" );

# reverse with start/end dates

$s1 = DateTime::SpanSet->from_sets( start_set => $end_set, end_set => $start_set );

my $iter = $s1->iterator;

my $res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq NEG_INFINITY.'..1810-09-20T00:00:00',
    "got $res" );

my $res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1811-10-21T00:00:00..1812-11-22T00:00:00',
    "got $res" );

my $res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1813-12-23T00:00:00..'.INFINITY,
    "got $res" );

# special case: end == start
{
my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
my $end1   = new DateTime( year => '1811', month => '10', day => '21' );
my $start2 = new DateTime( year => '1811', month => '10', day => '21' );
my $end2   = new DateTime( year => '1812', month => '11', day => '22' );

my $start_set = DateTime::Set->from_datetimes( dates => [ $start1, $start2 ] );
my $end_set   = DateTime::Set->from_datetimes( dates => [ $end1, $end2 ] );

my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );

my $iter = $s1->iterator;

my $res = $iter->next;
$res = $res->min->datetime . ".." . $res->max->datetime;
ok( $res eq '1810-09-20T00:00:00..1811-10-21T00:00:00',
    "got $res" );

my $res = $iter->next;
$res = $res->min->datetime . ".." . $res->max->datetime;
ok( $res eq '1811-10-21T00:00:00..1812-11-22T00:00:00',
    "got $res" );
}

# special case: start_set == end_set
{
my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
my $start2 = new DateTime( year => '1811', month => '10', day => '21' );
my $start3 = new DateTime( year => '1812', month => '11', day => '22' );
my $start4 = new DateTime( year => '1813', month => '12', day => '23' );

my $start_set = DateTime::Set->from_datetimes( 
       dates => [ $start1, $start2, $start3, $start4 ] );

my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $start_set );

my $iter = $s1->iterator;

my $res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq NEG_INFINITY.'..1810-09-20T00:00:00',
    "got $res" );

$res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1810-09-20T00:00:00..1811-10-21T00:00:00',
    "got $res" );

$res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1811-10-21T00:00:00..1812-11-22T00:00:00',
    "got $res" );

$res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1812-11-22T00:00:00..1813-12-23T00:00:00',
    "got $res" );

$res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1813-12-23T00:00:00..'.INFINITY,
    "got $res" );

}

# special case: start_set == end_set == recurrence
TODO:
{
local $TODO = "can't build spanset from recurrence";
my $start_set = DateTime::Set->from_recurrence(
       next  => sub { $_[0]->truncate( to => 'day' )
                           ->add( days => 1 ) },
       span => new DateTime::Span(
                   start => new DateTime( year =>  '1810', 
                                          month => '9',  
                                          day =>   '20' )
               ),
);

my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $start_set );

my $iter = $s1->iterator;

my $res = $iter->next;
$res = str($res->min) . ".." . str($res->max);
ok( $res eq '1810-09-20T00:00:00..1810-09-21T00:00:00',
    "got $res" );
}

1;

