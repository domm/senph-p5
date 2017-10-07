package Senf::Foo;
use Log::Any qw($log);
use Moose;

sub run {
    $log->infof("hello Senf");
}

1;
