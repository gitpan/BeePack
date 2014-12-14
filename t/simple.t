#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use BeePack qw( beepack bunpack );

my %data = (
  one => 'me',
  two => 'you',
  three => 3,
  four => 10241024
);

my $pack = beepack( %data );
my %back = bunpack( $pack );

is_deeply(\%data,\%back,'beepack->bunpack works');

done_testing;
