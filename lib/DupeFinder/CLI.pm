package DupeFinder::CLI;

use v5.32;
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage qw(pod2usage);
use File::Spec;
use DupeFinder::Config;
use DupeFinder::Scanner;
use DupeFinder::Hasher;
use DupeFinder::Reporter;
use DupeFinder::Actions;
use DupeFinder::Logger;

our $VERSION = '0.0.1';

sub new {
    my ($class) = @_;
    return bless {
        config   => undef,
        logger   => undef,
        scanner  => undef,
        reporter => undef,
        actions  => undef,
    }, $class;
}

sub run {
    my ($self, @args) = @_;
    local @ARGV = @args;
    
    my %opts = (
        config     => '',
        output     => '',
        format     => 'text',
        verbose    => 0,
        quiet      => 0,
        color      => 1,
        dry_run    => 1,
        min_size   => 1,
        max_size   => 0,
        extensions => '',
        algorithm  => 'SHA256',
        action     => 'report',
        keep       => 'first',
        move_dir   => '',
        help       => 0,
        version    => 0,
    );
    
    GetOptions(
        'c|config=s'     => \$opts{config},
        'o|output=s'     => \$opts{output},
        'f|format=s'     => \$opts{format},
        'v|verbose'      => \$opts{verbose},
        'q|quiet'        => \$opts{quiet},
        'C|no-color'     => sub { $opts{color} = 0 },
        'n|dry-run'      => \$opts{dry_run},
        'N|no-dry-run'   => sub { $opts{dry_run} = 0 },
        'm|min-size=i'   => \$opts{min_size},
        'M|max-size=i'   => \$opts{max_size},
        'e|extensions=s' => \$opts{extensions},
        'a|algorithm=s'  => \$opts{algorithm},
        'A|action=s'     => \$opts{action},
        'k|keep=s'       => \$opts{keep},
        'd|move-dir=s'   => \$opts{move_dir},
        'h|help'         => \$opts{help},
        'V|version'      => \$opts{version},
    ) or return $self->_usage(2);
    
    return $self->_version() if $opts{version};
    return $self->_usage(0) if $opts{help};
    
    my @dirs = @ARGV;
    unless (@dirs) {
        say STDERR "Error: No directories specified.";
        return $self->_usage(1);
    }
    
    $self->_init(\%opts);
    return $self->_execute(\%opts, @dirs);
}

sub _init {
    my ($self, $opts) = @_;
    
    $self->{config} = DupeFinder::Config->new(
        config_file => $opts->{config} || undef
    );
    
    my $cfg = $self->{config};
    $cfg->set($opts->{min_size}, 'scan', 'min_size') if $opts->{min_size};
    $cfg->set($opts->{max_size}, 'scan', 'max_size') if $opts->{max_size};
    $cfg->set($opts->{algorithm}, 'hash', 'algorithm') if $opts->{algorithm};
    
    $self->{logger} = DupeFinder::Logger->new(
        level => $opts->{verbose} ? 'DEBUG' : 'INFO',
        color => $opts->{color},
        quiet => $opts->{quiet},
    );
    
    my @exts = $opts->{extensions} ? split(/,/, $opts->{extensions}) : ();
    
    $self->{scanner} = DupeFinder::Scanner->new(
        min_size   => $cfg->get('scan', 'min_size'),
        max_size   => $cfg->get('scan', 'max_size'),
        extensions => \@exts,
        exclude_dirs => $cfg->get('scan', 'exclude_dirs'),
        hasher => DupeFinder::Hasher->new(
            algorithm => $cfg->get('hash', 'algorithm'),
        ),
    );
    
    $self->{reporter} = DupeFinder::Reporter->new(
        format  => $opts->{format},
        color   => $opts->{color},
        verbose => $opts->{verbose},
    );
    
    $self->{actions} = DupeFinder::Actions->new(
        dry_run => $opts->{dry_run},
        backup  => $cfg->get('actions', 'backup'),
    );
}

sub _execute {
    my ($self, $opts, @dirs) = @_;
    my $log = $self->{logger};
    
    $log->info("DupeFinder v$VERSION");
    $log->info("Scanning directories: " . join(', ', @dirs));
    
    my $stats = eval { $self->{scanner}->scan(@dirs) };
    if ($@) {
        $log->error("Scan failed: $@");
        return 1;
    }
    
    $log->info(sprintf("Scanned %d files (%s)", 
        $stats->{scanned}, 
        $self->_format_size($stats->{total_size})));
    
    $log->info("Finding duplicates...");
    my $duplicates = $self->{scanner}->find_duplicates();
    
    my $dup_stats = $self->{scanner}->get_duplicate_stats();
    $log->info(sprintf("Found %d duplicate groups (%d files, %s wasted)",
        $dup_stats->{groups},
        $dup_stats->{total_files},
        $self->_format_size($dup_stats->{wasted_bytes})));
    
    if ($opts->{action} eq 'report') {
        my $report = $self->{reporter}->report($duplicates, $stats);
        
        if ($opts->{output}) {
            $self->{reporter}->write_file($report, $opts->{output});
            $log->info("Report written to: $opts->{output}");
        } else {
            print $report;
        }
    }
    elsif ($opts->{action} eq 'delete') {
        my $deleted = $self->{actions}->delete_duplicates($duplicates, $opts->{keep});
        $log->info(sprintf("Deleted %d files", scalar @$deleted));
        say join("\n", @{$self->{actions}->get_log()}) if $opts->{verbose};
    }
    elsif ($opts->{action} eq 'hardlink') {
        my $linked = $self->{actions}->create_hardlinks($duplicates);
        $log->info(sprintf("Created %d hardlinks", scalar @$linked));
        say join("\n", @{$self->{actions}->get_log()}) if $opts->{verbose};
    }
    elsif ($opts->{action} eq 'move') {
        unless ($opts->{move_dir}) {
            $log->error("--move-dir required for move action");
            return 1;
        }
        my $moved = $self->{actions}->move_duplicates($duplicates, $opts->{move_dir}, $opts->{keep});
        $log->info(sprintf("Moved %d files to %s", scalar @$moved, $opts->{move_dir}));
        say join("\n", @{$self->{actions}->get_log()}) if $opts->{verbose};
    }
    else {
        $log->error("Unknown action: $opts->{action}");
        return 1;
    }
    
    return 0;
}

sub _format_size {
    my ($self, $bytes) = @_;
    my @units = qw(B KB MB GB TB);
    my $i = 0;
    while ($bytes >= 1024 && $i < $#units) {
        $bytes /= 1024;
        $i++;
    }
    return sprintf("%.2f %s", $bytes, $units[$i]);
}

sub _usage {
    my ($self, $code) = @_;
    print <<'USAGE';
Usage: dupefinder [OPTIONS] DIRECTORY...

Options:
  -c, --config FILE      Config file (YAML)
  -o, --output FILE      Output file for report
  -f, --format FORMAT    Output format: text, json, yaml, csv (default: text)
  -v, --verbose          Verbose output
  -q, --quiet            Suppress progress messages
  -C, --no-color         Disable colored output
  -n, --dry-run          Dry run mode (default)
  -N, --no-dry-run       Execute file operations
  -m, --min-size SIZE    Minimum file size in bytes (default: 1)
  -M, --max-size SIZE    Maximum file size in bytes (0 = unlimited)
  -e, --extensions EXT   Comma-separated file extensions to include
  -a, --algorithm ALGO   Hash algorithm: MD5, SHA1, SHA256, SHA512 (default: SHA256)
  -A, --action ACTION    Action: report, delete, hardlink, move (default: report)
  -k, --keep WHICH       Keep first or last file (default: first)
  -d, --move-dir DIR     Destination for moved duplicates
  -h, --help             Show this help
  -V, --version          Show version

Examples:
  dupefinder /home/user/photos
  dupefinder -f json -o report.json /data
  dupefinder -A delete -N -k first /tmp/downloads
  dupefinder -e jpg,png,gif -m 1024 /media
USAGE
    return $code;
}

sub _version {
    my ($self) = @_;
    say "DupeFinder v$VERSION";
    return 0;
}

1;

=head1 NAME

DupeFinder::CLI - Command-line interface handler

=head1 SYNOPSIS

    use DupeFinder::CLI;
    exit DupeFinder::CLI->new->run(@ARGV);

=head1 DESCRIPTION

Main CLI driver for DupeFinder application.

=head1 LICENSE

Apache License 2.0

=cut
