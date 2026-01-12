package DupeFinder::Scanner;

use v5.32;
use strict;
use warnings;
use File::Find;
use File::Spec;
use File::Basename qw(basename dirname);
use Carp qw(croak);
use DupeFinder::Hasher;

our $VERSION = '0.0.1';

sub new {
    my ($class, %args) = @_;
    return bless {
        min_size        => $args{min_size} // 1,
        max_size        => $args{max_size} // 0,
        follow_symlinks => $args{follow_symlinks} // 0,
        include_hidden  => $args{include_hidden} // 0,
        extensions      => $args{extensions} // [],
        exclude_dirs    => $args{exclude_dirs} // [],
        hasher          => $args{hasher} // DupeFinder::Hasher->new(),
        on_progress     => $args{on_progress},
        files           => [],
        size_groups     => {},
        duplicates      => {},
        stats           => { scanned => 0, skipped => 0, total_size => 0 },
    }, $class;
}

sub scan {
    my ($self, @dirs) = @_;
    croak "No directories specified" unless @dirs;
    
    $self->{files} = [];
    $self->{size_groups} = {};
    $self->{stats} = { scanned => 0, skipped => 0, total_size => 0 };
    
    my %exclude = map { $_ => 1 } @{$self->{exclude_dirs}};
    my %ext_filter = map { lc($_) => 1 } @{$self->{extensions}};
    my $has_ext_filter = scalar keys %ext_filter;
    
    for my $dir (@dirs) {
        croak "Directory not found: $dir" unless -d $dir;
        
        find({
            wanted => sub {
                return unless -f;
                my $path = $File::Find::name;
                my $name = basename($path);
                
                return if !$self->{include_hidden} && $name =~ /^\./;
                
                if ($has_ext_filter) {
                    my ($ext) = $name =~ /\.([^.]+)$/;
                    return unless $ext && $ext_filter{lc($ext)};
                }
                
                my $size = -s $path;
                return if $size < $self->{min_size};
                return if $self->{max_size} && $size > $self->{max_size};
                
                push @{$self->{files}}, { path => $path, size => $size };
                push @{$self->{size_groups}{$size}}, $path;
                $self->{stats}{scanned}++;
                $self->{stats}{total_size} += $size;
                
                $self->{on_progress}->($self->{stats}) if $self->{on_progress};
            },
            preprocess => sub {
                return grep { !$exclude{$_} && ($self->{include_hidden} || !/^\./) } @_;
            },
            follow => $self->{follow_symlinks},
            no_chdir => 1,
        }, $dir);
    }
    
    return $self->{stats};
}

sub find_duplicates {
    my ($self) = @_;
    $self->{duplicates} = {};
    
    for my $size (keys %{$self->{size_groups}}) {
        my @paths = @{$self->{size_groups}{$size}};
        next if @paths < 2;
        
        my %hash_groups;
        for my $path (@paths) {
            my $hash = $self->{hasher}->compute($path);
            next unless $hash;
            push @{$hash_groups{$hash}}, $path;
        }
        
        for my $hash (keys %hash_groups) {
            my @group = @{$hash_groups{$hash}};
            next if @group < 2;
            
            if ($hash =~ /^Q:/) {
                my %full_hash_groups;
                for my $path (@group) {
                    my $full = $self->{hasher}->hash_file($path);
                    next unless $full;
                    push @{$full_hash_groups{$full}}, $path;
                }
                for my $fh (keys %full_hash_groups) {
                    my @fg = @{$full_hash_groups{$fh}};
                    $self->{duplicates}{$fh} = \@fg if @fg > 1;
                }
            } else {
                $self->{duplicates}{$hash} = \@group;
            }
        }
    }
    
    return $self->{duplicates};
}

sub get_duplicate_stats {
    my ($self) = @_;
    my $groups = 0;
    my $files = 0;
    my $wasted = 0;
    
    for my $hash (keys %{$self->{duplicates}}) {
        my @paths = @{$self->{duplicates}{$hash}};
        $groups++;
        $files += @paths;
        my $size = -s $paths[0] // 0;
        $wasted += $size * (@paths - 1);
    }
    
    return {
        groups       => $groups,
        total_files  => $files,
        wasted_bytes => $wasted,
    };
}

sub files      { shift->{files} }
sub duplicates { shift->{duplicates} }
sub stats      { shift->{stats} }

1;

=head1 NAME

DupeFinder::Scanner - Directory scanner and duplicate detector

=head1 SYNOPSIS

    use DupeFinder::Scanner;
    my $scanner = DupeFinder::Scanner->new(min_size => 1024);
    $scanner->scan('/home/user/documents');
    my $dupes = $scanner->find_duplicates();

=head1 METHODS

=over 4

=item new(%args) - Create scanner instance

=item scan(@dirs) - Scan directories for files

=item find_duplicates() - Identify duplicate files by hash

=item get_duplicate_stats() - Get summary statistics

=back

=head1 LICENSE

Apache License 2.0

=cut
