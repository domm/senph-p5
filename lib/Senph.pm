package Senph;
use 5.026;

# ABSTRACT: simple comment system / disqus clone

our $VERSION = '0.001';

use Context::Singleton;

contrive '/Senph/App/senph.pl' => (
    class => 'Senph::Async',
    dep => {
        loop       => '/Senph/Async/Loop',
        mail_queue => '/Senph/Model/MailQueue',
        psgi       => '/Senph/PSGI/App',
    },
);

contrive '/Senph/App/disqus2senph.pl' => (
    class => 'Senph::Script::Disqus2Senph',
    dep => {
        comment_model => '/Senph/Model/Comment',
        dumpfile      => '/Senph/App/disqus2senph.pl/dumpfile',
    },
);

contrive '/Senph/PSGI/App' => (
    class => 'Senph::PSGI',
    dep => {
        approve_ctrl => '/Senph/Controller/Approve',
        comment_ctrl => '/Senph/Controller/Comment',
        router       => '/Senph/PSGI/Router',
    },
);

contrive '/Senph/PSGI/Router' => (
    class => 'Senph::PSGI::Router',
    builder => 'routes',
);

contrive '/Senph/Controller/Comment' => (
    class => 'Senph::PSGI::Ctrl::Comment',
    dep => {
        comment_model => '/Senph/Model/Comment',
    },
);

contrive '/Senph/Controller/Approve' => (
    class => 'Senph::PSGI::Ctrl::Approve',
    dep => {
        comment_model => '/Senph/Model/Comment',
    },
);

contrive '/Senph/Model/Comment' => (
    class => 'Senph::Model::Comment',
    dep => {
        mail_queue => '/Senph/Model/MailQueue',
        store      => '/Senph/Store/File',
    },
);

contrive '/Senph/Model/MailQueue/smtp_user' => (
    value => $ENV{SMTP_USER},
);

contrive '/Senph/Model/MailQueue/smtp_password' => (
    value => $ENV{SMTP_PASSWORD},
);

contrive '/Senph/Model/MailQueue/smtp_sender' => (
    value => $ENV{SMTP_SENDER},
);

contrive '/Senph/Model/MailQueue/instance' => (
    value => $ENV{INSTANCE},
);

contrive '/Senph/Model/MailQueue' => (
    class => 'Senph::Model::MailQueue',
    dep => {
        instance      => '/Senph/Model/MailQueue/instance',
        loop          => '/Senph/Async/Loop',
        rendered      => '/Senph/Template/Mail',
        smtp          => '/Senph/Async/SMTP',
        smtp_password => '/Senph/Model/MailQueue/smtp_password',
        smtp_sender   => '/Senph/Model/MailQueue/smtp_sender',
        smtp_user     => '/Senph/Model/MailQueue/smtp_user',
    },
);

contrive '/Senph/Store/File/basedir' => (
    value => $ENV{DATADIR} || './var/',
);

contrive '/Senph/Store/File' => (
    class => 'Senph::Store',
    dep => {
        basedir => '/Senph/Store/File/basedir',
    },
);

contrive '/Senph/Template/Mail/path' => (
    value => './root/mail/en',
);

contrive '/Senph/Template/Mail/cache_dir' => (
    value => './tmp/xslate_mail',
);

contrive '/Senph/Template/Mail' => (
    class => 'Text::Xslate',
    dep => {
        cache_dir => '/Senph/Template/Mail/cache_dir',
        path      => '/Senph/Template/Mail/path',
    },
);


contrive '/Senph/Async/Loop' => (
    class     => 'IO::Async::Loop',
);

contrive '/Senph/Async/HTTPClient/user_agent' => (
    value => __PACKAGE__ . '/' . $VERSION,
);

contrive '/Senph/Async/HTTPClient/timeout' => (
    value => 2,
);

contrive '/Senph/Async/HTTPClient' => (
    class => 'Net::Async::HTTP',
    dep => {
        timeout    => '/Senph/Async/HTTPClient/timeout',
        user_agent => '/Senph/Async/HTTPClient/user_agent',
    },
);

trigger  '/Senph/Async/HTTPClient' => sub {
    deduce ('/Senph/Async/Loop')->add ($_[0]);
};

contrive '/Senph/Async/SMTP/host' => (
    value => $ENV{SMTP_HOST},
);

contrive '/Senph/Async/SMTP' => (
    class => 'Net::Async::SMTP::Client',
    dep => {
        host => '/Senph/Async/SMTP/host',
    },
);

trigger  '/Senph/Async/SMTP' => sub {
    deduce ('/Senph/Async/Loop')->add ($_[0]);
};


1;

