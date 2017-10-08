package Senf::Model::Comment;
use 5.026;

# ABSTRACT: Comment Model

use Moose;
use MooseX::Types::Path::Tiny qw/Dir/;

has 'storage' => (
    is=>'ro',
    isa=>Dir,
    required=>1,
    coerce=>1,
);

use Moose;

sub load_site {
    my ($self, $ident) = @_;

    my $site = Senf::Object::Site->load($self->storage->child($ident,'site.json')->stringify);
    return $site;

}

sub load_topic {
    my ($self, $site, $ident) = @_;

    my $topic = Senf::Object::Topic->load($self->storage->child($site->ident,'topics',$ident.'.json')->stringify);
    return $topic;
}

sub create_comment {
    my ($self, $site, $topic, $comment_data) = @_;

    warn $topic->comment_count;    

    my $comment = Senf::Object::Comment->new(
        ident=>$topic->comment_count,
        subject=>$comment_data->{subject},
        comment=>$comment_data->{comment},
        created=>scalar localtime(),
    );

    push($topic->comments->@*,$comment);
    use Data::Dumper; $Data::Dumper::Maxdepth=3;$Data::Dumper::Sortkeys=1;warn Data::Dumper::Dumper $topic;

    $topic->store($self->storage->child($site->ident,'topics',$topic->ident.'.json')->stringify);

}



__PACKAGE__->meta->make_immutable;

