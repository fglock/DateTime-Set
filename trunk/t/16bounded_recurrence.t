#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 13;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::Infinite;
# use warnings;

#======================================================================
# recurrence
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

my $res;

my $t0 = new DateTime( year => '1810', month => '05', day => '01' );
my $t1 = new DateTime( year => '1810', month => '08', day => '01' );
my $t2 = new DateTime( year => '1810', month => '11', day => '01' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

{
    diag( "monthly from 1810-08-01 until infinity" );

    my $_next_month = sub {
            # warn "next of ". $_[0]->datetime;
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $_[0] if $_[0] >= $t1;
            return $t1->clone;
        };
    my $_previous_month = sub {
            # warn "previous of ". $_[0]->datetime;
            my $dt = $_[0]->clone;
            $_[0]->truncate( to => 'month' );
            $_[0]->subtract( months => 1 ) if $_[0] == $dt;
            return $_[0] if $_[0] >= $t1;
            return DateTime::Infinite::Past->new;
        };

my $months = DateTime::Set->from_recurrence(
    next =>     $_next_month,
    previous => $_previous_month,
);

    # contains datetime, semi-bounded set

    is( $months->contains( $t0 ), 0, "does not contain datetime" );
    is( $months->contains( $t0, $t2 ), 0, "does not contain datetime list" );
    is( $months->contains( $t2 ), 1, "contains datetime" );

    is( $months->intersects( $t0 ), 0, "does not intersect datetime" );
    is( $months->intersects( $t0, $t2 ), 1, "intersects datetime list" );
    is( $months->intersects( $t2 ), 1, "intersects datetime" );


$res = $months->min;
$res = $res->ymd if ref($res);
is( $res, '1810-08-01', 
    "min()" );
$res = $months->max;
# $res = $res->ymd if ref($res);
is( ref($res), 'DateTime::Infinite::Future',
    "max()" );

}

{
    diag( "monthly from infinity until 1810-08-01" );

    my $_next_month = sub {
            # warn "next of ". $_[0]->datetime;
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $_[0] if $_[0] <= $t1;
            return DateTime::Infinite::Future->new;
        };
    my $_previous_month = sub {
            # warn "previous of ". $_[0]->datetime;
            my $dt = $_[0]->clone;
            $_[0]->truncate( to => 'month' );
            $_[0]->subtract( months => 1 ) if $_[0] == $dt;
            return $_[0] if $_[0] <= $t1;
            return $t1->clone;
        };

my $months = DateTime::Set->from_recurrence(
    next =>     $_next_month,
    previous => $_previous_month,
);

$res = $months->min;
# $res = $res->ymd if ref($res);
is( ref($res), 'DateTime::Infinite::Past',
    "min()" );

$res = $months->max;
$res = $res->ymd if ref($res);
is( $res, '1810-08-01',   
    "max()" );

    is( $months->count, undef, "count" );

}


{
    diag( "monthly from 1810-08-01 until 1810-11-01" );

    my $_next_month = sub {
            # warn "next of ". $_[0]->datetime;
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $t1->clone if $_[0] < $t1;
            return $_[0] if $_[0] <= $t2;
            return DateTime::Infinite::Future->new;
        };
    my $_previous_month = sub {
            # warn "previous of ". $_[0]->datetime;
            my $dt = $_[0]->clone;
            $_[0]->truncate( to => 'month' );
            $_[0]->subtract( months => 1 ) if $_[0] == $dt;
            return DateTime::Infinite::Past->new if $_[0] < $t1;
            return $_[0] if $_[0] <= $t2;
            return $t2->clone;
        };

my $months = DateTime::Set->from_recurrence(
    next =>     $_next_month,
    previous => $_previous_month,
);

$res = $months->min;
$res = $res->ymd if ref($res);
is( $res, '1810-08-01',
    "min()" );

$res = $months->max;
$res = $res->ymd if ref($res);
is( $res, '1810-11-01',
    "max()" );

}

1;

