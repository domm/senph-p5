package Senf::API::Ctrl::Comment;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senf::Model::Comment',
    required => 1,
);

sub item {
    my ( $self, $req, $ident ) = @_;

    return $req->json_response( { hello => 'world ' . $ident } );
}

__PACKAGE__->meta->make_immutable;

