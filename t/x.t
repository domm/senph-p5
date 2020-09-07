#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 4;
use Test::Exception;

use Senph::X;

throws_ok {
    Senph::X::Forbidden->throw('forbidden');
} qr/Senph::X::Forbidden/;
is $@->http_status, 403, 'forbidden';

throws_ok {
    Senph::X::NotFound->throw('not-found');
} qr/Senph::X::NotFound/;
is $@->http_status, 404, 'not found';
