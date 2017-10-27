#!/usr/bin/env perl
use 5.026;
use strict;
use warnings;
use lib::projectroot qw(lib local::lib=local);

use Plack::Handler::Net::Async::HTTP::Server;
use Log::Any::Adapter;
use Module::Runtime 'use_module';

Log::Any::Adapter->set('Stderr', log_level => $ENV{LOGLEVEL} || 'info');

use Bread::Runner;
my $app = Bread::Runner->run('Senf',{service=>'api.psgi'});

my $handler = Plack::Handler::Net::Async::HTTP::Server->new(
    listen => [ ":8080" ],
    queuesize=>100,
);

$handler->run( $app );
