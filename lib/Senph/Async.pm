package Senph::Async;
use 5.026;
use Moose;

# ABSTRACT: combining all Async components

use Net::Async::HTTP::Server::PSGI;
use Net::Async::SMTP::Client;
use IO::Async::Timer::Periodic;

use Log::Any qw($log);

has 'loop' => (
    is       => 'ro',
    isa      => 'IO::Async::Loop',
    required => 1,
);

has 'mail_queue' => (
    is       => 'ro',
    isa      => 'Senph::Model::MailQueue',
    required => 1,
);

has 'psgi' => (
    is       => 'ro',
    isa      => 'Senph::PSGI',
    required => 1,
);

sub run {
    my $self = shift;

    my $httpserver =
        Net::Async::HTTP::Server::PSGI->new( app => $self->psgi->app );

    $self->loop->add($httpserver);

    my $port = $ENV{SENPH_PORT} || 8080;
    $httpserver->listen(
        addr => {
            family   => "inet",
            socktype => "stream",
            port     => $port,
        },
        on_listen_error => sub { die "Cannot listen - $_[-1]\n" },
    );
    $log->infof( "Starting up on http://localhost:%i", $port );

    my $timer = IO::Async::Timer::Periodic->new(
        interval       => 3,
        first_interval => 1,
        on_tick        => sub {
            $self->mail_queue->send;
        }
    );
    $timer->start;
    $self->loop->add($timer);

    $self->loop->run;
}

__PACKAGE__->meta->make_immutable;
