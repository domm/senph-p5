package Senph::Script::Disqus2Senph;
use strict;
use warnings;
use 5.026;

use Moose;
use MooseX::Types::Path::Tiny qw/Dir File/;

use Senph::Object::Site;
use Senph::Object::Topic;
use Senph::Object::Comment;

has 'dumpfile' => (
    is=>'ro',
    isa=>File,
    required=>1,
    coerce=>1,
    default=>'domm-plix-at-2017-10-14T19_22_56.750499-all.xml',
);

has 'comment_model' => (
    is=>'ro',
    required=>1,
);

use XML::Simple;

sub run {
    my $self = shift;

    my $in = XMLin($self->dumpfile->stringify);

    my %raw_topics;
    foreach my $t ($in->{thread}->@*) {
        $raw_topics{$t->{'dsq:id'}} = $t;
    }
    my %topics;
    my @posts;
    foreach my $p ($in->{post}->@*) {
        next if $p->{isDeleted} eq 'true' || $p->{isSpam} eq 'true';

        my $raw_topic = $raw_topics{$p->{thread}{'dsq:id'}};

        my $link = $raw_topic->{link};

        my $topic = $self->comment_model->store->load_topic($link);
        $topics{$raw_topic->{'dsq:id'}} = $topic;
        push(@posts, $p);
    }

    foreach my $p (@posts) {
        next if $p->{isDeleted} eq 'true' || $p->{isSpam} eq 'true';
        my %data = (
            ident=>'0',
            body=>$p->{message},
            created=>$p->{createdAt},
            status=>'online',
            user_notify=>'none',
            memo=>'imported from disqus '.$p->{'dsq:id'},
        );
        if ($p->{author}{isAnonymous} eq 'true') {
            $data{user_name} = 'anonymous';
        }
        else {
            $data{user_name} = $p->{author}{name};
            $data{user_email} = $p->{author}{email} if !ref($p->{author}{email}); # ARGH, XML::Simple...
        }

        my $topic = $topics{$p->{thread}{'dsq:id'}};

        if ($p->{parent}) {
            warn $p->{parent}{'dsq:id'};
        }

        #my $comment = $self->comment_model->create_comment($topic, \%data);

    }
}

1;
