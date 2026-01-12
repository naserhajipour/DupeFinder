package DupeFinder::Reporter;

use v5.32;
use strict;
use warnings;
use JSON::PP;
use YAML::XS qw(Dump);
use File::Basename qw(basename);
use Term::ANSIColor qw(colored);

our $VERSION = '0.0.1';

sub new {
    my ($class, %args) = @_;
    return bless {
        format  => $args{format} // 'text',
        color   => $args{color} // 1,
        verbose => $args{verbose} // 0,
        output  => $args{output},
    }, $class;
}

sub report {
    my ($self, $duplicates, $stats) = @_;
    
    my $method = "_format_" . $self->{format};
    return $self->$method($duplicates, $stats);
}

sub _format_text {
    my ($self, $duplicates, $stats) = @_;
    my @lines;
    
    push @lines, $self->_heading("Duplicate Files Report");
    push @lines, "";
    
    if ($stats) {
        push @lines, $self->_heading("Scan Statistics", 2);
        push @lines, sprintf("  Files scanned: %d", $stats->{scanned} // 0);
        push @lines, sprintf("  Total size: %s", $self->_format_size($stats->{total_size} // 0));
        push @lines, "";
    }
    
    my $dup_stats = $self->_calc_dup_stats($duplicates);
    push @lines, $self->_heading("Duplicate Statistics", 2);
    push @lines, sprintf("  Duplicate groups: %d", $dup_stats->{groups});
    push @lines, sprintf("  Duplicate files: %d", $dup_stats->{files});
    push @lines, sprintf("  Wasted space: %s", $self->_format_size($dup_stats->{wasted}));
    push @lines, "";
    
    if (%$duplicates) {
        push @lines, $self->_heading("Duplicate Groups", 2);
        my $group_num = 1;
        
        for my $hash (sort keys %$duplicates) {
            my @paths = @{$duplicates->{$hash}};
            my $size = -s $paths[0] // 0;
            
            my $header = sprintf("Group %d [%s, %d files]", 
                $group_num++, $self->_format_size($size), scalar @paths);
            push @lines, $self->_colorize($header, 'cyan');
            
            for my $path (sort @paths) {
                push @lines, "  " . $path;
            }
            push @lines, "";
        }
    } else {
        push @lines, $self->_colorize("No duplicates found.", 'green');
    }
    
    return join("\n", @lines);
}

sub _format_json {
    my ($self, $duplicates, $stats) = @_;
    my $data = {
        stats      => $stats,
        dup_stats  => $self->_calc_dup_stats($duplicates),
        duplicates => $duplicates,
    };
    return JSON::PP->new->pretty->canonical->encode($data);
}

sub _format_yaml {
    my ($self, $duplicates, $stats) = @_;
    my $data = {
        stats      => $stats,
        dup_stats  => $self->_calc_dup_stats($duplicates),
        duplicates => $duplicates,
    };
    return Dump($data);
}

sub _format_csv {
    my ($self, $duplicates, $stats) = @_;
    my @lines = ("hash,size,path");
    
    for my $hash (sort keys %$duplicates) {
        my @paths = @{$duplicates->{$hash}};
        my $size = -s $paths[0] // 0;
        for my $path (@paths) {
            my $escaped = $path;
            $escaped =~ s/"/""/g;
            push @lines, qq{"$hash",$size,"$escaped"};
        }
    }
    
    return join("\n", @lines);
}

sub _calc_dup_stats {
    my ($self, $duplicates) = @_;
    my ($groups, $files, $wasted) = (0, 0, 0);
    
    for my $hash (keys %$duplicates) {
        my @paths = @{$duplicates->{$hash}};
        $groups++;
        $files += @paths;
        my $size = -s $paths[0] // 0;
        $wasted += $size * (@paths - 1);
    }
    
    return { groups => $groups, files => $files, wasted => $wasted };
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

sub _heading {
    my ($self, $text, $level) = @_;
    $level //= 1;
    return $self->_colorize($text, $level == 1 ? 'bold yellow' : 'bold white');
}

sub _colorize {
    my ($self, $text, $color) = @_;
    return $self->{color} ? colored($text, $color) : $text;
}

sub write_file {
    my ($self, $content, $path) = @_;
    open my $fh, '>:encoding(UTF-8)', $path or die "Cannot write to $path: $!";
    print $fh $content;
    close $fh;
    return 1;
}

1;

=head1 NAME

DupeFinder::Reporter - Output formatting for duplicate reports

=head1 SYNOPSIS

    use DupeFinder::Reporter;
    my $reporter = DupeFinder::Reporter->new(format => 'json');
    print $reporter->report($duplicates, $stats);

=head1 METHODS

=over 4

=item new(%args) - Create reporter (format, color, verbose)

=item report($duplicates, $stats) - Generate formatted report

=item write_file($content, $path) - Write report to file

=back

=head1 LICENSE

Apache License 2.0

=cut
