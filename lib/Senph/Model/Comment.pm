package Senph::Model::Comment;
use 5.026;

# ABSTRACT: Comment Model

use Moose;
use MooseX::Types::Path::Tiny qw/Dir/;
use Log::Any qw($log);

use Email::Simple;

has 'store' => (
    is       => 'ro',
    isa      => 'Senph::Store',
    required => 1,
);

has 'mail_queue' => (
    is       => 'ro',
    isa      => 'Senph::Model::MailQueue',
    required => 1,
);

sub show_topic {
    my ( $self, $ident ) = @_;

    my $site  = $self->store->load_site($ident);
    my $topic = $self->store->load_topic($ident);

    if ( !$topic->show_comments || !$site->global_show_comments ) {
        Senph::X::Forbidden->throw(
            {   ident   => 'show-comments-disabled',
                message => 'Showing comments is disabled here',
            }
        );
    }

    my %data = map { $_ => $topic->$_ } qw(url);
    my @comments = $self->walk_comments($topic);
    $data{comments} = \@comments;

    return \%data;
}

sub walk_comments {
    my ( $self, $topic ) = @_;
    my @list;
    foreach my $comment ( $topic->all_comments ) {
        my %comment = map { $_ => $comment->$_ }
            qw (body created user_name user_email ident);
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
    my ( $self, $topic_url, $comment_data ) = @_;

    my $site  = $self->store->load_site($topic_url);
    my $topic = $self->store->load_topic($topic_url);

    $comment_data->{ident} = $topic->comment_count;
    my $comment = $self->_do_create( $site, $topic, $topic, $comment_data );

    $self->mail_queue->enqueue(
        Email::Simple->create(
            header => [
                From    => 'robot@plix.at',
                To      => 'domm@plix.at',
                Subject => 'test',
            ],
            attributes => {
                encoding => "8bitmime",
                charset  => "UTF-8",
            },
            body => 'hallo!',
        )
    );

    $self->notify_approve($site, $topic, $comment) if $comment->status eq 'pending';

    $log->infof( "New comment create on %s as %s",
        $topic->url, $comment->ident );
    return $comment;
}

sub create_reply {
    my ( $self, $topic_url, $reply_to_ident, $comment_data ) = @_;

    my $site     = $self->store->load_site($topic_url);
    my $topic    = $self->store->load_topic($topic_url);
    my $reply_to = $self->store->load_comment( $topic, $reply_to_ident );

    unless ( $reply_to->status eq 'online' ) {
        Senph::X::Forbidden->throw(
            {   ident   => 'cannot-reply-non-online-comment',
                message => "You cannot reply to a comment that's not online",
            }
        );
    }

    $comment_data->{ident} = $reply_to_ident . '.' . $reply_to->comment_count;
    my $reply = $self->_do_create( $site, $topic, $reply_to, $comment_data );

    $self->notify_approve($site, $topic, $reply) if $reply->status eq 'pending';
    $self->notify_watcher($site, $topic, $reply_to, $reply);

    $log->infof( "New reply created on %s as %s", $topic->url,
        $reply->ident );
    return $reply;
}

sub _do_create {
    my ( $self, $site, $topic, $parent, $comment_data ) = @_;

    if ( !$topic->allow_comments || !$site->global_allow_comments ) {
        Senph::X::Forbidden->throw(
            {   ident   => 'create-comments-disabled',
                message => 'New comments are not accepted here',
            }
        );
    }

    if ( $topic->require_approval || $site->global_require_approval ) {
        $comment_data->{status} = 'pending';
    }
    else {
        $comment_data->{status} = 'online';
    }

    my $comment = Senph::Object::Comment->new( $comment_data->%* );

    push( $parent->comments->@*, $comment );
    $self->store->store_topic($topic);

    # TODO init verify author email if author wants notifications

    return $comment;
}

sub notify_approve {
    my ($self, $site, $topic, $comment) = @_;
    $self->mail_queue->create(
        {   to      => $site->owner_email,
            subject => sprintf( 'New comment on %s, please approve',
                $site->name ),
            body => "To approve, open this link:\n\n"
            . $comment # TODO URL
        }
    );
}

sub notify_watcher {
    my ($self, $site, $topic, $reply_to, $reply) = @_;

    if ( $reply_to->user_notify && $reply_to->user_email_is_verified ) {
        # "Get notified if somebody replies to this post"
        $self->mail_queue->create(
            {   to      => $reply_to->user_email,
                subject => sprintf( 'Somebody replied to your comment on %s',
                    $topic->url ),
                body => "Here's the reply:\n\n"
                    . $reply->user_name
                    . "said: \n"
                    . $reply->body . "\n\n"
                    . $topic->url . "\n\n"
                    . "Unsubscribe from this comment: TODO\n"
                    . "Unsubscribe from this topic:   TODO\n"
            }
        );
    }

    # TODO check if other users or watching this topic
    # "Get notified on any activity on this topic"

}

__PACKAGE__->meta->make_immutable;

