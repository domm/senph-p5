package Senph;
use 5.026;

# ABSTRACT: simple comment system / disqus clone

our $VERSION = '0.001';

use Bread::Board;

use Module::Runtime 'use_module';

use Senph::X;

use Senph::Object::Site;
use Senph::Object::Topic;
use Senph::Object::Comment;

my $c = container 'Senph' => as {
    container 'App' => as {
        service 'senph.pl' => (
            class        => 'Senph::Async',
            lifecycle    => 'Singleton',
            dependencies => {
                psgi       => '/PSGI/App',
                loop       => '/Async/Loop',
                mail_queue => '/Model/MailQueue',
            }
        );
        service 'disqus2senph.pl' => (
            class        => 'Senph::Script::Disqus2Senph',
            lifecycle    => 'Singleton',
            dependencies => { comment_model => '/Model/Comment' }
        );
    };

    container 'PSGI' => as {
        service 'App' => (
            class        => 'Senph::PSGI',
            lifecycle    => 'Singleton',
            dependencies => {
                router       => '/PSGI/Router',
                comment_ctrl => '/Controller/Comment',
                approve_ctrl => '/Controller/Approve',
            }
        );
        service 'Router' => (
            class     => 'Router::Simple',
            lifecycle => 'Singleton',
            block     => sub {
                use_module('Senph::PSGI::Router');
                return Senph::PSGI::Router->routes;
            }
        );
    };

    container 'Controller' => as {
        service 'Comment' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::PSGI::Ctrl::Comment',
            dependencies => { comment_model => '/Model/Comment' }
        );
        service 'Approve' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::PSGI::Ctrl::Approve',
            dependencies => { comment_model => '/Model/Comment' }
        );
    };

    container 'Model' => as {
        service 'Comment' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::Model::Comment',
            dependencies => {
                store      => '/Store/File',
                mail_queue => '/Model/MailQueue',
            }
        );
        service 'MailQueue' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::Model::MailQueue',
            dependencies => {
                smtp          => '/Async/SMTP',
                smtp_user     => literal($ENV{SMTP_USER}),
                smtp_password => literal($ENV{SMTP_PASSWORD}),
                smtp_sender   => literal($ENV{SMTP_SENDER}),
                renderer      => '/Template/Mail',
                instance      => literal($ENV{INSTANCE}),
                loop       => '/Async/Loop',
            }
        );
    };

    container 'Store' => as {
        service 'File' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::Store',
            dependencies => {
                basedir     => literal($ENV{DATADIR} || './var/'),
                loop        => '/Async/Loop',
                http_client => '/Async/HTTPClient',
            }
        );
    };

    container 'Template' => as {
        service 'Mail' => (
            lifecycle    => 'Singleton',
            class        => 'Text::Xslate',
            dependencies => {
                path      => literal('./root/mail/en'),      # only en for now
                cache_dir => literal('./tmp/xslate_mail'),
            }
        );
    };

    container 'Async' => as {
        service 'Loop' => (
            lifecycle => 'Singleton',
            class     => 'IO::Async::Loop',
        );
        service 'HTTPClient' => (
            lifecycle    => 'Singleton',
            class        => 'Net::Async::HTTP',
            dependencies => { loop => 'Loop', },
            block        => sub {
                my $s    = shift;
                my $loop = $s->param('loop');
                my $http = Net::Async::HTTP->new(
                    user_agent => __PACKAGE__ . '/' . $VERSION,
                    timeout    => 2,
                );
                $loop->add($http);
                return $http;
            },
        );
        service 'SMTP' => (
            lifecycle    => 'Singleton',
            class        => 'Net::Async::SMTP::Client',
            dependencies => { loop => 'Loop', },
            block        => sub {
                my $s    = shift;
                my $loop = $s->param('loop');
                my $smtp =
                    Net::Async::SMTP::Client->new(
                    host => $ENV{SMTP_HOST});
                $loop->add($smtp);
                return $smtp;
            },
        );
    };

};

sub init {
    return $c;
}

1;

