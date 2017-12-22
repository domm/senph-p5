package Senf::Store;
use 5.026;

# ABSTRACT: very basic file store

use Moose;
use MooseX::Types::Path::Tiny qw/Dir/;
use Digest::SHA1 q(sha1_hex);
use URI;
use Log::Any qw($log);

has 'basedir' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has 'loop' => (
    is       => 'ro',
    required => 1,
);

has 'http_client' => (
    is       => 'ro',
    required => 1,
);

sub load_site {
    my ( $self, $ident ) = @_;

    if (blessed($ident)) {
        if ($ident->isa('Senf::Object::Site')) {
            return $ident;
        }
        if ($ident->isa('Senf::Object::Topic')) {
            $ident = $ident->url;
        }
    }

    my $file = $self->basedir->child( $self->_site_path($ident) );
    if ( -e $file ) {
        return Senf::Object::Site->load( $file->stringify );
    }

    Senf::X::NotFound->throw(
        {   ident   => 'site-not-found',
            message => 'Site "%{site}s" not found',
            site    => $ident,
        }
    );
}

sub load_topic {
    my ( $self, $ident ) = @_;

    return $ident if blessed($ident) && $ident->isa('Senf::Object::Topic');

    my $file = $self->basedir->child( $self->_topic_path($ident) );

    if ( -e $file ) {
        return Senf::Object::Topic->load( $file->stringify );
    }
    else {
        my $topic;
        my $future = $self->http_client->HEAD( URI->new($ident) )->on_done(
            sub {
                my $res = shift;
                if ( $res->code == 200 ) {
                    my $site = $self->load_site($ident);

                    $topic = Senf::Object::Topic->new(
                        url              => $ident,
                        show_comments    => $site->default_show_comments,
                        allow_comments   => $site->default_allow_comments,
                        require_approval => $site->default_require_approval,
                    );
                    $self->store_topic($topic);
                    $log->infof( "New topic created: %s", $topic->url );
                }
                else {
                    # TODO this X seems to be caught by Future/IO::Async and then passed on as a string
                    Senf::X::NotFound->throw(
                        {   ident   => 'invalid-topic',
                            message => 'Topic "%{topic}s" not available',
                            topic   => $ident,
                        }
                    );
                }
            }
            )->on_fail(
            sub {
                my $err = shift;

                # TODO this X kills the server..
                Senf::X::NotFound->throw(
                    {   ident => 'site-not-reachable',
                        message =>
                            'Cannot contact "%{topic}s" to validate topic',
                        topic       => $ident,
                        http_status => 500,
                    }
                );
            }
            );
        $self->loop->await($future);
        return $topic if $topic;

        # TODO not sure how to reach this X
        Senf::X->throw(
            {   ident       => 'cannot-create-topic',
                message     => 'Topic %{topic}s could not be created',
                topic       => $ident,
                http_status => 500,
            }
        );
    }
}

sub load_comment {
    my ( $self, $topic_ident, $comment_ident ) = @_;

    my $topic = $self->load_topic($topic_ident);

    my $comment;
    my @path = grep {/^\d+$/} split( /\./, $comment_ident );
    my $path = join( '->comments->', map { '[' . $_ . ']' } @path );  # oida!
    my $loder = '$comment = $topic->comments->' . $path;              # oida!!
    eval $loder;    # oida!!!
    return $comment;
}

sub store_topic {
    my ( $self, $topic ) = @_;

    my $file = $self->basedir->child( $self->_topic_path( $topic->url ) );
    $file->parent->mkpath;
    $topic->store( $file->stringify );
}

sub _topic_path {
    my ( $self, $uri ) = @_;

    $uri = URI->new($uri) unless blessed($uri) && $uri->isa('URI');

    my $sha1 = sha1_hex( $uri->path );
    my @path = $sha1 =~ /^(.{2})(.{2})(.*)$/;
    return join( '/', $uri->host, 'topics', @path ) . '.json';
}

sub _site_path {
    my ( $self, $uri ) = @_;
warn "IN SITE_{PATH $uri";
    $uri = URI->new($uri) unless blessed($uri) && $uri->isa('URI');
    return join( '/', $uri->host, 'site.json' );
}

__PACKAGE__->meta->make_immutable;

