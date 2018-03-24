package Senph::API::AsyncPSGI;
use 5.026;
use Moose;

# ABSTRACT: a handrolled async web server

use Plack::Builder;
use Router::Simple;
use Senph::API::Request;
use Net::Async::HTTP::Server::PSGI;
use Net::Async::SMTP::Client;
use IO::Async::Timer::Periodic;
use Email::Simple;

use Log::Any qw($log);

has 'comment_ctrl' => (
    is       => 'ro',
    isa      => 'Senph::API::Ctrl::Comment',
    required => 1,
);

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

sub run {
    my $self = shift;

    my $router = Router::Simple->new();
    $router->connect( '/api/comment/:topic',
        { controller => 'comment_ctrl', action => 'topic', rest => 1 } );
    $router->connect( '/api/comment/:topic/:reply_to',
        { controller => 'comment_ctrl', action => 'reply', rest => 1 } );
    $router->connect( '/web/approve/:topic/',
        { controller => 'approve_ctrl', action => 'form' } );
    $router->connect( '/web/verify-mail/:comment/:secret',
        { controller => 'approve_ctrl', action => 'form' } );
    $router->connect( '/web/manage/:comment/:secret',
        { controller => 'approve_ctrl', action => 'form' } );


    my $api = sub {
        my $env = shift;
        my $req = Senph::API::Request->new_from_env($env);

        if ( my $p = $router->match($env) ) {
            my $ctrl   = delete $p->{controller};
            my $action = delete( $p->{action} );
            if ( delete $p->{rest} ) {
                $action .= '_' . $req->method;
            }
            unless ( $self->$ctrl->can($action) ) {

                # TODO HEAD requests? Or handle via Middleware::CORS?
                return [
                    405,
                    [],
                    [         $req->method
                            . ' is not allowed on '
                            . $env->{REQUEST_URI}
                    ]
                ];
            }
            my $rv = $self->$ctrl->$action( $req, $p );
            return $rv->finalize;
        }
        else {
            return [ 404, [], ['not found'] ];
        }
    };

    my $builder = Plack::Builder->new;
    $builder->add_middleware('Plack::Middleware::PrettyException');
    my $app = $builder->wrap($api);

    my $httpserver = Net::Async::HTTP::Server::PSGI->new( app => $app );

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
