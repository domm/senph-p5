package Senf::Model::Comment;
use 5.026;

# ABSTRACT: Comment Model

use Moose;
use MooseX::Types::Path::Tiny qw/Dir/;

has 'storage' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

use Moose;

sub load_site {
    my ( $self, $ident ) = @_;

    return $ident if ref($ident);    # it's already an object

    my $site = Senf::Object::Site->load(
        $self->storage->child( $ident, 'site.json' )->stringify );

    # TODO 403 exception if site is disabled?
    return $site;
}

sub load_topic {
    my ( $self, $site_ident, $ident ) = @_;

    return $ident if ref($ident);    # it's already an object
    my $site = $self->load_site($site_ident);

    my $topic = Senf::Object::Topic->load(
        $self->storage->child( $site->ident, 'topics', $ident . '.json' )
            ->stringify );

    # TODO 403 exception if topic is disabled?
    return wantarray ? ( $topic, $site ) : $topic;
}

sub load_comment {
    my ( $self, $site_ident, $topic_ident, $comment_ident ) = @_;

    my $topic = $self->load_topic( $site_ident, $topic_ident );

    my $comment;
    my @path = grep {/^\d+$/} split( /\./, $comment_ident );
    my $path = join( '->comments->', map { '[' . $_ . ']' } @path );  # oida!
    my $loder = '$comment = $topic->comments->' . $path;              # oida!!
    eval $loder;    # oida!!!
    return $comment;
}

sub show_topic {
    my ( $self, $site_ident, $topic_ident ) = @_;

    my ( $topic, $site ) = $self->load_topic( $site_ident, $topic_ident );

    my %data = map { $_ => $topic->$_ } qw(ident url status);
    my @comments = $self->walk_comments($topic);
    $data{comments} = \@comments;

    return \%data;
}

sub walk_comments {
    my ( $self, $topic ) = @_;
    my @list;
    foreach my $comment ( $topic->all_comments ) {
        my %comment = map { $_ => $comment->$_ }
            qw (subject body created user_name user_email);
        if ( $comment->is_deleted ) {
            %comment = map { $_ => 'deleted' } keys %comment;
        }
        next unless $comment->status eq 'online';
        if ( $comment->comment_count ) {
            my @replies = $self->walk_comments($comment);
            $comment{comments} = \@replies;
        }
        push( @list, \%comment );
    }
    return @list;
}

sub create_comment {
    my ( $self, $site_ident, $topic_ident, $comment_data ) = @_;

    my ( $topic, $site ) = $self->load_topic( $site_ident, $topic_ident );

    $comment_data->{ident} = $topic->comment_count;
    $self->_do_create( $site, $topic, $topic, $comment_data );
}

sub create_reply {
    my ( $self, $site_ident, $topic_ident, $reply_to_ident, $comment_data ) =
        @_;

    my ( $topic, $site ) = $self->load_topic( $site_ident, $topic_ident );
    my $reply_to = $self->load_comment( $site, $topic, $reply_to_ident );

    $comment_data->{ident} = $reply_to_ident . '.' . $reply_to->comment_count;
    $self->_do_create( $site, $topic, $reply_to, $comment_data );
}

sub _do_create {
    my ( $self, $site, $topic, $parent, $comment_data ) = @_;

    my $comment = Senf::Object::Comment->new( $comment_data->%* );
    push( $parent->comments->@*, $comment );
    $self->store_topic( $site, $topic );
}

sub store_topic {
    my ( $self, $site, $topic ) = @_;

    $topic->store(
        $self->storage->child( $site->ident, 'topics',
            $topic->ident . '.json' )->stringify
    );
}

__PACKAGE__->meta->make_immutable;

