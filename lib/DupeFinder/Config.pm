package DupeFinder::Config;

use v5.32;
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use File::Spec;
use Carp qw(croak);

our $VERSION = '0.0.1';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        config_file => $args{config_file},
        config      => {},
    }, $class;
    $self->_load_defaults();
    $self->load($args{config_file}) if $args{config_file};
    return $self;
}

sub _load_defaults {
    my ($self) = @_;
    $self->{config} = {
        scan => {
            min_size       => 1,
            max_size       => 0,
            follow_symlinks => 0,
            include_hidden => 0,
            extensions     => [],
            exclude_dirs   => ['.git', '.svn', 'node_modules', '__pycache__'],
        },
        hash => {
            algorithm   => 'SHA256',
            chunk_size  => 65536,
            quick_hash  => 1,
        },
        output => {
            format      => 'text',
            color       => 1,
            verbose     => 0,
        },
        actions => {
            dry_run     => 1,
            backup      => 1,
            backup_dir  => '',
        },
    };
}

sub load {
    my ($self, $file) = @_;
    return unless $file && -f $file;
    
    my $yaml;
    eval { $yaml = LoadFile($file); };
    if ($@) {
        croak "Failed to parse config file '$file': $@";
    }
    
    $self->_merge_config($self->{config}, $yaml);
    $self->{config_file} = $file;
    return 1;
}

sub _merge_config {
    my ($self, $base, $override) = @_;
    for my $key (keys %$override) {
        if (ref $base->{$key} eq 'HASH' && ref $override->{$key} eq 'HASH') {
            $self->_merge_config($base->{$key}, $override->{$key});
        } else {
            $base->{$key} = $override->{$key};
        }
    }
}

sub get {
    my ($self, @path) = @_;
    my $val = $self->{config};
    for my $key (@path) {
        return undef unless ref $val eq 'HASH' && exists $val->{$key};
        $val = $val->{$key};
    }
    return $val;
}

sub set {
    my ($self, $value, @path) = @_;
    return unless @path;
    my $ref = $self->{config};
    for my $i (0 .. $#path - 1) {
        $ref->{$path[$i]} //= {};
        $ref = $ref->{$path[$i]};
    }
    $ref->{$path[-1]} = $value;
}

sub all { shift->{config} }

1;

=head1 NAME

DupeFinder::Config - Configuration management for DupeFinder

=head1 SYNOPSIS

    use DupeFinder::Config;
    my $cfg = DupeFinder::Config->new(config_file => 'config.yaml');
    my $algo = $cfg->get('hash', 'algorithm');

=head1 METHODS

=over 4

=item new(%args) - Create config instance

=item load($file) - Load YAML config file

=item get(@path) - Get nested config value

=item set($value, @path) - Set config value

=item all() - Return full config hash

=back

=head1 LICENSE

Apache License 2.0

=cut
