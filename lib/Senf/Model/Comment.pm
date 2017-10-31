package Senf::Model::Comment;
use 5.026;

# ABSTRACT: Comment Model

use Moose;
use MooseX::Types::Path::Tiny qw/Dir/;
use Log::Any qw($log);

has 'storage' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has 'loop' => (
    is=>'ro',
    required=>1,
);

has 'http_client' => (
    is=>'ro',
    required=>1,
);

sub load_site {
    my ( $self, $ident ) = @_;

    return $ident if ref($ident);    # it's already an object

    my $file = $self->storage->child( $ident, 'site.json' );
    if (-e $file) {
        my $site = Senf::Object::Site->load($file->stringify);
        return $site;
    }

    Senf::X::NotFound->throw({
        ident=>'site-not-found',
        message=>'Site "%{site}s" not found',
        site=>$ident,
    });
}

sub load_topic {
    my ( $self, $site_ident, $ident ) = @_;

    return $ident if ref($ident);    # it's already an object
    my $site = $self->load_site($site_ident);

    my $file = $self->storage->child( $site->ident, 'topics', $ident . '.json' );
    # the following should happen in a new find_or_create method
    if (1==0 && !-e $file) {
        my $future = $self->http_client->HEAD(
            URI->new( "https://domm.plix.at/perl/2017_08_things_i_learned_at_european_perl_conference_2018_amsterdam.html" ),
        )
        ->on_done(sub {
            my $res = shift;
            # TODO create new topic-storage-file based on site
            $log->infof("OK ".$res);
        })
        ->on_fail(sub {
            my $err = shift;
            Senf::X::NotFound->throw({
                ident=>'invalid-topic',
                message=>'Topic "%{topic}s" not available',
                topic=>$ident,
                site=>$site->ident,
            });
        });
        $self->loop->await($future);
    }

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

    if (!$topic->show_comments || !$site->show_comments) {
        Senf::X::Forbidden->throw({
            ident=>'show-comments-disabled',
            message=>'Showing comments is disabled here',
        });
    }

    my %data = map { $_ => $topic->$_ } qw(ident url);
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
    $log->infof("New comment create on %s", $topic->ident);
}

sub create_reply {
    my ( $self, $site_ident, $topic_ident, $reply_to_ident, $comment_data ) =
        @_;

    my ( $topic, $site ) = $self->load_topic( $site_ident, $topic_ident );
    my $reply_to = $self->load_comment( $site, $topic, $reply_to_ident );

    unless ($reply_to->status eq 'online') {
        Senf::X::Forbidden->throw({
            ident=>'cannot-reply-non-online-comment',
            message=>"You cannot reply to a comment that's not online",
        });
    }

    $comment_data->{ident} = $reply_to_ident . '.' . $reply_to->comment_count;
    $self->_do_create( $site, $topic, $reply_to, $comment_data );
}

sub _do_create {
    my ( $self, $site, $topic, $parent, $comment_data ) = @_;

    if (!$topic->allow_comments || !$site->allow_comments) {
        Senf::X::Forbidden->throw({
            ident=>'create-comments-disabled',
            message=>'New comments are not accepted here',
        });
    }

    if ($topic->require_approval || $site->require_approval) {
        $comment_data->{status} = 'pending';
    }
    else {
        $comment_data->{status} = 'online';
    }

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

