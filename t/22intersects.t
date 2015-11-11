use Test::More;
use strict;
use warnings;

BEGIN {
    if (eval 'use DateTime::Event::Recurrence; 1') {
        plan tests => 3;
    }
    else {
        plan skip_all => 'DateTime::Event::Recurrence required for this test.';
    }
}

my $hourly   = DateTime::Event::Recurrence->hourly;
my $next_day = DateTime::Span->from_datetimes(
    start => DateTime->now,
    end   => DateTime->now->add( days => 1 )
);
my $future = DateTime::Span->from_datetimes( start => DateTime->now );

ok( $next_day->intersects($future), "next day intersects future" );
ok( $hourly->intersects($next_day), "hourly event intersects next day" );
ok( $hourly->intersects($future), "hourly event intersects future" );

