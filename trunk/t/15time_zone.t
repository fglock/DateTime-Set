#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 11;

use DateTime;
use DateTime::Set;

#======================================================================
# TIME ZONE TESTS
#====================================================================== 

my $t1 = new DateTime( year => '2001', month => '11', day => '22' );
my $t2 = new DateTime( year => '2002', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );


my $s2 = $s1->set_time_zone( 'Asia/Taipei' );

is( $s2->min->datetime, '2001-11-22T00:00:00', 
    'got 2001-11-22T00:00:00 - min' );

is( $s2->min->time_zone->name, 'Asia/Taipei', 
    'got time zone name from set' );

my $span1 = DateTime::Span->from_datetimes( start => $t1, end => $t2 );
$span1->set_time_zone( 'America/Sao_Paulo' );
my $span2 = $span1->clone;

$span1->set_time_zone( 'Asia/Taipei' );

is( $span1->start->datetime, '2001-11-22T10:00:00',
    'got 2001-11-22T10:00:00 - min' );
is( $span1->end->datetime, '2002-11-22T10:00:00',
    'got 2002-11-22T10:00:00 - max' );

# check for immutability
is( $span2->start->datetime, '2001-11-22T00:00:00',
    'got 2001-11-22T00:00:00 - min' );
is( $span2->end->datetime, '2002-11-22T00:00:00',
    'got 2002-11-22T00:00:00 - max' );

# recurrence
{
my $months = DateTime::Set->from_recurrence(
                 recurrence => sub {
                     $_[0]->truncate( to => 'month' )->add( months => 1 );
                 }
             )
             ->set_time_zone( 'Asia/Taipei' );

my $str = $months->next( $t1 )->datetime . ' ' .
          $months->next( $t1 )->time_zone_long_name;

my $original = $t1->datetime . ' ' .
               $t1->time_zone_long_name;

is( $str, '2001-12-01T00:00:00 Asia/Taipei', 'recurrence with time zone' );
is( $original, '2001-11-22T00:00:00 floating', 'does not mutate arg' );

TODO: {
  local $TODO = "Time zone settings do not backtrack";
  # bug reported by Tim Mueller-Seydlitz

  my $t3 = $t1->clone->set_time_zone( 'America/Sao_Paulo' );
  my $str = $months->next( $t3 )->datetime . ' ' .
            $months->next( $t3 )->time_zone_long_name;
  is( $str, '2001-12-01Txx:00:00 America/Sao_Paulo', 'recurrence with time zone, arg has time zone' );
}

# set locale, add duration
is ( $months->clone->add( days => 1 )->
              next( $t1 )->
              strftime( "%a" ), 'Sun', 
     'default locale' );

is ( $months->clone->add( days => 1 )->
              set( locale => 'pt_BR' )->
              next( $t1 )->
              strftime( "%a" ), 
     'Dom', 
     'new locale' );
}

1;

