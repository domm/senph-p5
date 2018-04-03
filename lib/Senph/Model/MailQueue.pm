package Senph::Model::MailQueue;
use 5.026;

# ABSTRACT: MailQueue Model

use Moose;
use Log::Any qw($log);

use Email::Simple;

has 'queue' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        queued    => 'elements',
        enqueue   => 'push',
        next_mail => 'shift',
    }
);

has 'renderer' => (
    is       => 'ro',
    isa      => 'Text::Xslate',
    required => 1,
);

has 'smtp' => (
    is       => 'ro',
    isa      => 'Net::Async::SMTP::Client',
    required => 1,
);

has [ 'smtp_user', 'smtp_password', 'smtp_sender' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'instance' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

use IO::Async::Timer::Countdown;

has 'loop' => (
    is       => 'ro',
    isa      => 'IO::Async::Loop',
    required => 1,
);

has 'ppr' => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
);

sub create_notify_new_comment {    #: to site-owner: delete-link, approve-link
    my ( $self, $args ) = @_;

    my $comment = $args->{comment};
    my $topic_ident = $args->{topic}->url;
    if ($self->ppr->{$topic_ident}) {
        $log->debugf("Ignoring notify_new_comment on %s because we just sent one...", $topic_ident);
        return;
    }

    $self->create(
        {   template => 'owner_new_comment.tx',
            to       => 'domm@plix.at',
            subject  => sprintf( 'New comment on %s', $args->{topic}->url ),
            data     => {
                comment => {
                    user_name  => $comment->user_name,
                    user_email => $comment->user_email,
                    body       => $comment->body,
                },
            }
        }
    );
    $self->ppr->{$topic_ident} = 1;

    my $timer = IO::Async::Timer::Countdown->new(
        delay => 10,
        on_expire => sub {
            $self->ppr->{$topic_ident} = 0;
            $log->debugf("Stop blocking %s ", $topic_ident);
        },
    );
    $timer->start;

    $self->loop->add( $timer );
}

# sub create_approve: to site-owner; approve-link, delete-link
# sub create_verification: to author; verify-link, delete-link, settings-link?
# sub create_notify_reply: to author; view-link, unsubscribe-link
# sub create_notify_activity: to subscribers: view-link, unsubscribe-link
# sub create_blacklist: to email; optout-link

sub create {
    my ( $self, $args ) = @_;

    $log->debugf( "Creating mail '%s' for %s", $args->{subject},
        $args->{to} );

    my $data = $args->{data};
    $data->{senph} = {
        version  => $Senph::VERSION,
        instance => $self->instance,
    };
    my $body = $self->renderer->render( $args->{template}, $data );

    $self->enqueue(
        Email::Simple->create(
            header => [
                To      => $args->{to},
                Subject => $args->{subject},
            ],
            attributes => {
                encoding => "8bitmime",
                charset  => "UTF-8",
            },
            body => $body,
        )
    );
}

sub send {
    my $self = shift;

    return unless $self->queued;

    my $s = $self->smtp;
    $s->connected->then(
        sub {
            $s->login(
                user => $self->smtp_user,
                pass => $self->smtp_password,
            );
        }
    )->get;

    while ( my $email = $self->next_mail ) {
        $log->infof(
            "Sending mail '%s' to %s",
            $email->header('subject'),
            $email->header('to')
        );

        eval {
            $s->send(
                to   => $email->header('to'),
                from => $self->smtp_sender,
                data => $email->as_string,
            )->get;
        };
        if ($@) {
            $log->errorf( "Could not send mail: %s", $@ );
        }
    }
    $s->quit->get;
}

__PACKAGE__->meta->make_immutable;

