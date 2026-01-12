package DupeFinder::Logger;

use v5.32;
use strict;
use warnings;
use POSIX qw(strftime);
use Term::ANSIColor qw(colored);
use File::Path qw(make_path);
use File::Basename qw(dirname);

our $VERSION = '0.0.1';

my %LEVELS = (DEBUG => 0, INFO => 1, WARN => 2, ERROR => 3, FATAL => 4);
my %COLORS = (DEBUG => 'white', INFO => 'green', WARN => 'yellow', ERROR => 'red', FATAL => 'bold red');

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        level    => $LEVELS{uc($args{level} // 'INFO')} // 1,
        color    => $args{color} // 1,
        file     => $args{file},
        fh       => undef,
        quiet    => $args{quiet} // 0,
    }, $class;
    
    if ($self->{file}) {
        my $dir = dirname($self->{file});
        make_path($dir) unless -d $dir;
        open $self->{fh}, '>>:encoding(UTF-8)', $self->{file} 
            or die "Cannot open log file: $!";
    }
    
    return $self;
}

sub _log {
    my ($self, $level, $msg) = @_;
    return if $LEVELS{$level} < $self->{level};
    
    my $ts = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $line = "[$ts] [$level] $msg";
    
    unless ($self->{quiet}) {
        my $display = $self->{color} 
            ? colored("[$level]", $COLORS{$level}) . " $msg"
            : $line;
        say STDERR $display;
    }
    
    if ($self->{fh}) {
        say {$self->{fh}} $line;
    }
}

sub debug { shift->_log('DEBUG', shift) }
sub info  { shift->_log('INFO', shift) }
sub warn  { shift->_log('WARN', shift) }
sub error { shift->_log('ERROR', shift) }
sub fatal { shift->_log('FATAL', shift) }

sub set_level {
    my ($self, $level) = @_;
    $self->{level} = $LEVELS{uc($level)} // 1;
}

sub DESTROY {
    my ($self) = @_;
    close $self->{fh} if $self->{fh};
}

1;

=head1 NAME

DupeFinder::Logger - Structured logging utility

=head1 SYNOPSIS

    use DupeFinder::Logger;
    my $log = DupeFinder::Logger->new(level => 'DEBUG', file => 'app.log');
    $log->info("Starting scan");

=head1 METHODS

=over 4

=item new(%args) - Create logger (level, color, file, quiet)

=item debug/info/warn/error/fatal($msg) - Log at level

=item set_level($level) - Change log level

=back

=head1 LICENSE

Apache License 2.0

=cut
