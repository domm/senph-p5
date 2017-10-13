package Senf::API::Ctrl::Comment;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senf::Model::Comment',
    required => 1,
);

sub list {
    my ( $self, $req, $s, $t ) = @_;

    my $site = $self->comment_model->load_site($s);
    my $topic = $self->comment_model->load_topic($site, $t);

    return $req->json_response($topic->pack);
}

sub create {
    my ( $self, $req, $site_ident, $topic_ident ) = @_;

    my $args = {
        subject => $req->param('subject'),
        comment => $req->param('comment'),
        user_name => $req->param('user_name'),
    };

    my $topic = $self->comment_model->load_topic($site_ident,$topic_ident);

    $self->comment_model->create_comment($site_ident, $topic, $args);

    return $req->json_response($topic->pack);
}

sub reply {}
sub publish {}
sub edit {}
sub delete {}



__PACKAGE__->meta->make_immutable;

