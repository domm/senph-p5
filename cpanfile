requires 'lib::projectroot';
requires 'Bread::Runner';
requires 'IO::Async';
requires 'Log::Any';
requires 'Throwable::X';
requires 'Config::ZOMG';

requires 'Cpanel::JSON::XS';
requires 'JSON::MaybeXS';
requires 'Unicode::UTF8';
requires 'Path::Tiny';
requires 'Data::UUID';
requires 'Time::Moment';
requires 'Digest::SHA1';

requires 'MooseX::Storage';
requires 'MooseX::Types::URI';
requires 'MooseX::Types::Path::Tiny';
requires 'MooseX::Types::Email';

requires 'Web::Request';
requires 'Plack';
requires 'Plack::Handler::Starman';
requires 'HTTP::Throwable::Factory';
requires 'Plack::Middleware::PrettyException' => '1.005';
requires 'Plack::Middleware::CrossOrigin';
requires 'Web::Request::Role::JSON';
requires 'Web::Request::Role::Response';

requires 'Plack::Handler::Net::Async::HTTP::Server';
requires 'Net::Async::HTTP';
requires 'IO::Async::SSL';
requires 'Router::Simple';
requires 'Net::Async::SMTP' => '0.002';
requires 'Text::Xslate';

