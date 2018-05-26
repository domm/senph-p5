package Senph::PSGI;
use 5.026;
use Moose;

# ABSTRACT: a handrolled PSGI app

use Plack::Builder;
use Senph::PSGI::Request;

use Log::Any qw($log);

has 'router' => (
    is       => 'ro',
    isa      => 'Router::Simple',
    required => 1,
);

has 'comment_ctrl' => (
    is       => 'ro',
    isa      => 'Senph::PSGI::Ctrl::Comment',
    required => 1,
);

has 'approve_ctrl' => (
    is       => 'ro',
    isa      => 'Senph::PSGI::Ctrl::Approve',
    required => 1,
);

sub app {
    my $self = shift;

    my $app = sub {
        my $env = shift;

        if ( my $match = $self->router->match($env) ) {
            my $req    = Senph::PSGI::Request->new_from_env($env);
            my $ctrl   = delete $match->{controller};
            my $action = delete $match->{action};
            if ( delete $match->{rest} ) {
                $action .= '_' . $req->method;
            }

            unless ( $self->$ctrl->can($action) ) {
                return [
                    405,
                    [],
                    [         $req->method
                            . ' is not allowed on '
                            . $env->{REQUEST_URI}
                    ]
                ];
            }
            my $rv = $self->$ctrl->$action( $req, $match );
            return $rv->finalize;
        }
        else {
            return [ 404, [], ['not found'] ];
        }
    };

    my $builder = Plack::Builder->new;
    $builder->add_middleware('Plack::Middleware::PrettyException');
    $builder->add_middleware('Plack::Middleware::CrossOrigin', origins => '*', headers=>'*');
    return $builder->wrap($app);
}

__PACKAGE__->meta->make_immutable;
