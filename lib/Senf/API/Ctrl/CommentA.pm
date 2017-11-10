package Senf::API::Ctrl::CommentA;
use 5.026;

# ABSTRACT: API Controller for comment

use Moose;
use URI::Escape;

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senf::Model::Comment',
    required => 1,
);

sub topic_GET {
    my ( $self, $req, $args ) = @_;

    my $topic = $self->comment_model->show_topic(uri_unescape($args->{topic}));
    return $req->json_response($topic);
}

sub topic_POST {
    my ( $self, $req, $rawargs ) = @_;

    my $args = $self->_unpack_args($rawargs);
    my $create = {
        subject => $req->param('subject'),
        body => $req->param('body'),
        user_name => $req->param('user_name'),
        user_notify => $req->param('user_notify'),
    };

    #warn "start create ".time();
    #    my ( $response ) = $http->do_request(
    #        method=>'HEAD',
    #        uri => URI->new( "https://domm.plix.at/perl/2017_08_things_i_learned_at_european_perl_conference_2018_amsterdam.html" ),
    #    )->get;
    #    warn $response->as_string;
    $self->comment_model->create_comment($args->{site}, $args->{topic}, $create);
warn "done create ".time();

    my $topic = $self->comment_model->show_topic($args->{site}, $args->{topic});
    return $req->json_response($topic);
}

sub reply_POST {
    my ( $self, $req, $rawargs ) = @_;

    my $args = $self->_unpack_args($rawargs);
    my $create = {
        subject => $req->param('subject'),
        body => $req->param('body'),
        user_name => $req->param('user_name'),
        user_notify => $req->param('user_notify'),
    };

    $self->comment_model->create_reply($args->{site}, $args->{topic}, $args->{comment}, $create);


    my $topic = $self->comment_model->show_topic($args->{site}, $args->{topic});
    return $req->json_response($topic);
}

sub publish {}
sub edit {}
sub delete {}

__PACKAGE__->meta->make_immutable;

