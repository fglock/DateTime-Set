use strict;

use Test::More;
plan tests => 19;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::SpanSet;

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

sub str { ref($_[0]) ? $_[0]->datetime : $_[0] }
sub span_str { str($_[0]->min) . '..' . str($_[0]->max) }

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

my $res = span_str( $iter->next );
ok( $res eq '1810-09-20T00:00:00..1811-10-21T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
ok( $res eq '1812-11-22T00:00:00..1813-12-23T00:00:00',
    "got $res" );

# reverse with start/end dates

$s1 = DateTime::SpanSet->from_sets( start_set => $end_set, end_set => $start_set );

my $iter = $s1->iterator;

$res = span_str( $iter->next );
ok( $res eq NEG_INFINITY.'..1810-09-20T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
ok( $res eq '1811-10-21T00:00:00..1812-11-22T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
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

$res = span_str( $iter->next );
ok( $res eq '1810-09-20T00:00:00..1811-10-21T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
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

$res = span_str( $iter->next );
ok( $res eq NEG_INFINITY.'..1810-09-20T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
ok( $res eq '1810-09-20T00:00:00..1811-10-21T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
ok( $res eq '1811-10-21T00:00:00..1812-11-22T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
ok( $res eq '1812-11-22T00:00:00..1813-12-23T00:00:00',
    "got $res" );

$res = span_str( $iter->next );
ok( $res eq '1813-12-23T00:00:00..'.INFINITY,
    "got $res" );

}

# special case: start_set == end_set == recurrence
{
    my $start_set = DateTime::Set->from_recurrence(
       next  => sub { $_[0]->truncate( to => 'day' )
                           ->add( days => 1 ) },
       span => new DateTime::Span(
                   start => new DateTime( year =>  '1810', 
                                          month => '9',  
                                          day =>   '20' )
               ),
    );

# test is the recurrence works properly
    my $set_iter = $start_set->iterator;

    $res = str( $set_iter->next );
    ok( $res eq '1810-09-20T00:00:00',
        "recurrence works properly - got $res" );
    $res = str( $set_iter->next );
    ok( $res eq '1810-09-21T00:00:00',
        "recurrence works properly - got $res" );

# create spanset
    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $start_set );
    my $iter = $s1->iterator;

    $res = span_str( $iter->next );
    ok( $res eq '-inf..1810-09-20T00:00:00',
        "start_set == end_set recurrence works properly - got $res" );

    $res = span_str( $iter->next );
    ok( $res eq '1810-09-20T00:00:00..1810-09-21T00:00:00',
        "start_set == end_set recurrence works properly - got $res" );

    $res = span_str( $iter->next );
    ok( $res eq '1810-09-21T00:00:00..1810-09-22T00:00:00',
        "start_set == end_set recurrence works properly - got $res" );
}

# set_and_duration
{
    my $start_set = DateTime::Set->from_recurrence(
       next  => sub { $_[0]->truncate( to => 'day' )
                           ->add( days => 1 ) },
       span => new DateTime::Span(
                   start => new DateTime( year =>  '1810',
                                          month => '9',
                                          day =>   '20' )
               ),
    );
    my $span_set = DateTime::SpanSet->from_set_and_duration(
                       set => $start_set, hours => 1 );

    my $iter = $span_set->iterator;

    $res = span_str( $iter->next );
    ok( $res eq '1810-09-20T00:00:00..1810-09-20T01:00:00',
        "start_set == end_set recurrence works properly - got $res" );

    $res = span_str( $iter->next );
    ok( $res eq '1810-09-21T00:00:00..1810-09-21T01:00:00',
        "start_set == end_set recurrence works properly - got $res" );
}

1;

