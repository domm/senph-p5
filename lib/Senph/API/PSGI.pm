package Senph::PSGI;
use 5.026;
use Moose;

# ABSTRACT: a handrolled PSGI app

use Plack::Builder;
use Router::Simple;
use Senph::PSGI::Request;

use Log::Any qw($log);

has 'comment_ctrl' => (
    is       => 'ro',
    isa      => 'Senph::PSGI::API::Comment',
    required => 1,
);

has 'approve_ctrl' => (
    is       => 'ro',
    isa      => 'Senph::PSGI::Web::Approve',
    required => 1,
);

sub app {
    my $self = shift;

    my $router = Router::Simple->new();
    $router->connect( '/api/comment/:topic',
        { controller => 'comment_ctrl', action => 'topic', rest => 1 } );
    $router->connect( '/api/comment/:topic/:reply_to',
        { controller => 'comment_ctrl', action => 'reply', rest => 1 } );
    $router->connect( '/web/approve/:topic/:secret',
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
    return $builder->wrap($api);
}

__PACKAGE__->meta->make_immutable;
