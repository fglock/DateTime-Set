#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 3;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# SPAN TESTS
#====================================================================== 


{
    my $t1 = new DateTime( year => 1810, month => 11, day => 22 );
    my $t2 = new DateTime( year => 1900, month => 11, day => 22 );
    my $s1 = DateTime::Span->from_datetime_and_duration( start => $t1, hours => 2 );

    my $res = $s1->min->ymd.'T'.$s1->min->hms;
    ok( $res eq '1810-11-22T00:00:00',
        "got $res - min" );

    $res = $s1->max->ymd.'T'.$s1->max->hms;
    ok( $res eq '1810-11-22T02:00:00',
        "got $res - max" );
}

{
    my $t1 = new DateTime( year => 1800 );
    my $t2 = new DateTime( year => 1900 );

    my $mid = new DateTime( year => 1850 );

    my $span = DateTime::Span->from_datetimes( start => $t1, end => $t2 );

    ok( $span->contains($mid),
        "Span should contain datetime in between start and end" );
}


1;

