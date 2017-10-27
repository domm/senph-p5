package Senf::API::Async;
use 5.026;
use Moose;

# ABSTRACT: a handroled async web server

use Router::Simple;
use Senf::API::Request;
use Net::Async::HTTP::Server::PSGI;
use Log::Any qw($log);

has 'comment_ctrl' => (
    is       => 'ro',
    isa      => 'Senf::API::Ctrl::CommentA',
    required => 1,
);

has 'loop' => (
    is=>'ro',
    isa=>'IO::Async::Loop',
    required=>1,
);

sub run {
    my $self = shift;

    my $router = Router::Simple->new();
    $router->connect('/api/comment/:site/:topic', {controller => 'comment_ctrl', action => 'topic', rest=>1});
    $router->connect('/api/comment/:site/:topic/:reply_to', {controller => 'comment_ctrl', action => 'reply', rest=>1});

    my $app = sub {
        my $env = shift;
        my $req = Senf::API::Request->new_from_env($env);

        if (my $p = $router->match($env)) {
            my $ctrl = delete $p->{controller};
            my $action = delete ($p->{action});
            if (delete $p->{rest}) {
                $action.='_'.$req->method;
            }
            unless ($self->$ctrl->can($action)) {
                # TODO HEAD requests?
                return [405,[],[$req->method .' is not allowed on '.$env->{REQUEST_URI}]];
            }
            my $rv = $self->$ctrl->$action($req, $p);
            return $rv->finalize;
        }
        else {
            return [404, [], ['not found']];
        }
    };

    my $httpserver = Net::Async::HTTP::Server::PSGI->new(
        app => $app
    );

    $self->loop->add( $httpserver );

    $httpserver->listen(
        addr => { family   => "inet",socktype => "stream", port => 8080 },
        on_listen_error => sub { die "Cannot listen - $_[-1]\n" },
    );

    $self->loop->run;
}

__PACKAGE__->meta->make_immutable;

