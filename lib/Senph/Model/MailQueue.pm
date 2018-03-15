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

sub create {
    my ( $self, $args ) = @_;

    $log->debugf( "Creating mail '%s' for %s", $args->{subject},
        $args->{to} );
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
            body => $args->{body} . <<"EOFOOTER",

-- 
Senph $Senph::VERSION
https://senph.plix.at
Never send me an email again:  TODO/blacklist
EOFOOTER
        )
    );
}

sub send {
    my $self = shift;

    my $s = $self->smtp;
    while ( my $email = $self->next_mail ) {
        $log->infof(
            "Sending mail '%s' to %s",
            $email->header('subject'),
            $email->header('to')
        );

        eval {
            # does not work if mail-server closed connection due to timeout. Maybe reconnect here?
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
}

__PACKAGE__->meta->make_immutable;

