package Senph::API::Ctrl::Comment;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;
use URI::Escape;

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senph::Model::Comment',
    required => 1,
);

sub topic_GET {
    my ( $self, $req, $args ) = @_;

    my $topic =
        $self->comment_model->show_topic( uri_unescape( $args->{topic} ) );
    return $req->json_response($topic);
}

sub topic_POST {
    my ( $self, $req, $args ) = @_;

    my $topic  = uri_unescape( $args->{topic} );
    my $payload = $req->json_payload;

    $self->comment_model->create_comment( $topic, $payload );

    my $data = $self->comment_model->show_topic($topic);
    return $req->json_response($data);
}

sub reply_POST {
    my ( $self, $req, $args ) = @_;

    my $topic  = uri_unescape( $args->{topic} );
    my $payload = $req->json_payload;

    $self->comment_model->create_reply( $topic, $args->{reply_to}, $create );

    my $data = $self->comment_model->show_topic($topic);
    return $req->json_response($data);
}

sub publish { }
sub edit    { }
sub delete  { }

__PACKAGE__->meta->make_immutable;

