package Senf::API::Ctrl::Comment;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senf::Model::Comment',
    required => 1,
);

sub topic_GET {
    my ( $self, $req, $site_ident, $topic_ident ) = @_;

    my $topic = $self->comment_model->show_topic($site_ident, $topic_ident);

    return $req->json_response($topic);
}

sub topic_POST {
    my ( $self, $req, $site_ident, $topic_ident ) = @_;

    my $args = {
        subject => $req->param('subject'),
        body => $req->param('body'),
        user_name => $req->param('user_name'),
    };

    $self->comment_model->create_comment($site_ident, $topic_ident, $args);

    my $topic = $self->comment_model->show_topic($site_ident, $topic_ident);
    return $req->json_response($topic);
}

sub reply {}
sub publish {}
sub edit {}
sub delete {}



__PACKAGE__->meta->make_immutable;

