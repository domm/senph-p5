package Senph::PSGI::Ctrl::Comment;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;
use MIME::Base64 qw(decode_base64url);

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senph::Model::Comment',
    required => 1,
);

sub index {
    my ( $self, $req) = @_;
    return $req->json_response({ version=>$Senph::VERSION, claim=>'simple comment system' });
}

sub topic_GET {
    my ( $self, $req, $args ) = @_;

    my $topic =
        $self->comment_model->show_topic( decode_base64url( $args->{topic} ) );
    return $req->json_response($topic);
}

sub topic_POST {
    my ( $self, $req, $args ) = @_;

    my $topic  = decode_base64url( $args->{topic} );
    my $payload = $req->json_payload;

    my $comment = $self->comment_model->create_comment( $topic, $payload );

    my $data = $self->comment_model->show_topic($topic);
    return $req->json_response({
        status=>$comment->status,
        topic=> $data
    });
}

sub reply_POST {
    my ( $self, $req, $args ) = @_;

    my $topic  = decode_base64url( $args->{topic} );
    my $payload = $req->json_payload;

    my $comment = $self->comment_model->create_reply( $topic, $args->{reply_to}, $payload );

    my $data = $self->comment_model->show_topic($topic);
    return $req->json_response({
        status=>$comment->status,
        topic=> $data
    });
}

sub publish { }
sub edit    { }
sub delete  { }

__PACKAGE__->meta->make_immutable;

