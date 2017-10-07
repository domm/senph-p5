package Senf::API::Ctrl::Comment;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;

sub item {
    my ( $self, $req, $ident ) = @_;

    return $req->json_response( { hello => 'world ' . $ident } );
}

__PACKAGE__->meta->make_immutable;

