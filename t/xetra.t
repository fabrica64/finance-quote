#!/usr/bin/perl -w

use strict;
use warnings;

use constant DEBUG => $ENV{DEBUG};
use if DEBUG, 'Smart::Comments';

use Test::More;
use Finance::Quote;
use Date::Simple qw(today);
use Scalar::Util qw(looks_like_number);
use Date::Range;
use Date::Manip;

if (not $ENV{ONLINE_TEST}) {
    plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}

my %valid    = ('IE0031442068'      => 'XETR',
                'IE0031442068.XFRA' => 'XFRA',
                'IE0031442068.XETR' => 'XETR',
                'IE00B4L5YC18'      => 'XETR',
                'IE00B4L5YC18.XFRA' => 'XFRA',
                'IE00B4L5YC18.XETR' => 'XETR',
               );

my @invalid  = ('BOGUS');
my @symbols  = (keys %valid, @invalid);

my $method   = 'xetra';  # Name of the target method for testing
my $currency = 'EUR';    # expected quote curreny
my $today    = today();  # together with $window, validate date/isodate  
my $window   = 7;        # quote must be within last $window days

my %check    = (# Tests are called with (value_to_test, symbol, quote_hash_reference)
                'success'  => sub {$_[0]},
                'symbol'   => sub {$_[0] eq (split(/[.]/, $_[1]))[0]},
                'method'   => sub {$_[0] eq $method},
                'currency' => sub {$_[0] eq $currency},
                'exchange' => sub {$_[0] eq $valid{$_[1]}},
                'close'    => sub {looks_like_number($_[0])},
                'last'     => sub {looks_like_number($_[0])},
                'high'     => sub {looks_like_number($_[0])},
                'low'      => sub {looks_like_number($_[0])},
                'isodate'  => sub {Date::Range->new($today - $window, $today)->includes(Date::Simple::ISO->new($_[0]))},
                'date'     => sub {my $a = Date::Manip::Date->new(); $a->parse_format('%m/%d/%Y', $_[0]);
                                   my $b = Date::Manip::Date->new(); $b->parse_format('%Y-%m-%d', $_[2]->{$_[1], 'isodate'});
                                   return $a->cmp($b) == 0;},
               );
my $q        = Finance::Quote->new();

plan tests => 1 + %check*%valid + @invalid;

my %quotes = $q->fetch($method, @symbols);
ok(%quotes);

### [<now>] quotes: %quotes

foreach my $symbol (keys %valid) {
  while (my ($key, $lambda) = each %check) {
    ok($lambda->($quotes{$symbol, $key}, $symbol, \%quotes), "$key -> $quotes{$symbol, $key}");
  }
}
    
foreach my $symbol (@invalid) {
  ok((not $quotes{'BOGUS', 'success'}), 'failed as expected');
}
