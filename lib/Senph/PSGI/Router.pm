package Senph::PSGI::Router;
use 5.026;

# ABSTRACT: define routes

use Router::Simple;

sub routes {
    my $self = shift;

    my $router = Router::Simple->new();
    $router->connect( '/',
        { controller => 'comment_ctrl', action => 'index' } );
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
    return $router;
}

1;
