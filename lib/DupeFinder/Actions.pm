package DupeFinder::Actions;

use v5.32;
use strict;
use warnings;
use File::Copy qw(move copy);
use File::Path qw(make_path);
use File::Spec;
use File::Basename qw(dirname basename);
use Carp qw(croak);

our $VERSION = '0.0.1';

sub new {
    my ($class, %args) = @_;
    return bless {
        dry_run    => $args{dry_run} // 1,
        backup     => $args{backup} // 1,
        backup_dir => $args{backup_dir} // '',
        verbose    => $args{verbose} // 0,
        log        => [],
    }, $class;
}

sub delete_duplicates {
    my ($self, $duplicates, $keep) = @_;
    $keep //= 'first';
    my @deleted;
    
    for my $hash (keys %$duplicates) {
        my @paths = sort @{$duplicates->{$hash}};
        my @to_delete = $keep eq 'first' ? @paths[1..$#paths] : @paths[0..$#paths-1];
        
        for my $path (@to_delete) {
            if ($self->_delete_file($path)) {
                push @deleted, $path;
            }
        }
    }
    
    return \@deleted;
}

sub _delete_file {
    my ($self, $path) = @_;
    return 0 unless -f $path;
    
    $self->_log("DELETE: $path");
    
    if ($self->{dry_run}) {
        $self->_log("  [DRY RUN] Would delete");
        return 1;
    }
    
    if ($self->{backup}) {
        my $backup_path = $self->_backup_path($path);
        $self->_log("  Backing up to: $backup_path");
        my $dir = dirname($backup_path);
        make_path($dir) unless -d $dir;
        copy($path, $backup_path) or do {
            $self->_log("  ERROR: Failed to backup: $!");
            return 0;
        };
    }
    
    unlink($path) or do {
        $self->_log("  ERROR: Failed to delete: $!");
        return 0;
    };
    
    return 1;
}

sub create_hardlinks {
    my ($self, $duplicates) = @_;
    my @linked;
    
    for my $hash (keys %$duplicates) {
        my @paths = sort @{$duplicates->{$hash}};
        my $original = shift @paths;
        
        for my $path (@paths) {
            if ($self->_hardlink($original, $path)) {
                push @linked, { original => $original, link => $path };
            }
        }
    }
    
    return \@linked;
}

sub _hardlink {
    my ($self, $source, $target) = @_;
    
    $self->_log("HARDLINK: $target -> $source");
    
    if ($self->{dry_run}) {
        $self->_log("  [DRY RUN] Would create hardlink");
        return 1;
    }
    
    if ($self->{backup}) {
        my $backup_path = $self->_backup_path($target);
        my $dir = dirname($backup_path);
        make_path($dir) unless -d $dir;
        copy($target, $backup_path) or do {
            $self->_log("  ERROR: Failed to backup: $!");
            return 0;
        };
    }
    
    unlink($target) or do {
        $self->_log("  ERROR: Failed to remove target: $!");
        return 0;
    };
    
    link($source, $target) or do {
        $self->_log("  ERROR: Failed to create hardlink: $!");
        return 0;
    };
    
    return 1;
}

sub move_duplicates {
    my ($self, $duplicates, $dest_dir, $keep) = @_;
    $keep //= 'first';
    my @moved;
    
    make_path($dest_dir) unless -d $dest_dir || $self->{dry_run};
    
    for my $hash (keys %$duplicates) {
        my @paths = sort @{$duplicates->{$hash}};
        my @to_move = $keep eq 'first' ? @paths[1..$#paths] : @paths[0..$#paths-1];
        
        for my $path (@to_move) {
            my $name = basename($path);
            my $dest = File::Spec->catfile($dest_dir, $name);
            
            my $counter = 1;
            while (-e $dest && !$self->{dry_run}) {
                my ($base, $ext) = $name =~ /^(.+?)(\.[^.]*)?$/;
                $dest = File::Spec->catfile($dest_dir, "${base}_${counter}" . ($ext // ''));
                $counter++;
            }
            
            if ($self->_move_file($path, $dest)) {
                push @moved, { from => $path, to => $dest };
            }
        }
    }
    
    return \@moved;
}

sub _move_file {
    my ($self, $source, $dest) = @_;
    
    $self->_log("MOVE: $source -> $dest");
    
    if ($self->{dry_run}) {
        $self->_log("  [DRY RUN] Would move file");
        return 1;
    }
    
    move($source, $dest) or do {
        $self->_log("  ERROR: Failed to move: $!");
        return 0;
    };
    
    return 1;
}

sub _backup_path {
    my ($self, $path) = @_;
    my $backup_dir = $self->{backup_dir} || File::Spec->catdir(dirname($path), '.dupefinder_backup');
    my $name = basename($path);
    return File::Spec->catfile($backup_dir, $name . '.' . time());
}

sub _log {
    my ($self, $msg) = @_;
    push @{$self->{log}}, $msg;
}

sub get_log   { shift->{log} }
sub clear_log { shift->{log} = [] }

1;

=head1 NAME

DupeFinder::Actions - File operations for duplicate handling

=head1 SYNOPSIS

    use DupeFinder::Actions;
    my $actions = DupeFinder::Actions->new(dry_run => 0);
    $actions->delete_duplicates($duplicates, 'first');

=head1 METHODS

=over 4

=item new(%args) - Create actions handler

=item delete_duplicates($dups, $keep) - Delete duplicate files

=item create_hardlinks($dups) - Replace duplicates with hardlinks

=item move_duplicates($dups, $dest, $keep) - Move duplicates to folder

=item get_log() - Get action log entries

=back

=head1 LICENSE

Apache License 2.0

=cut
