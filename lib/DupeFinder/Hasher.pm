package DupeFinder::Hasher;

use v5.32;
use strict;
use warnings;
use Digest::SHA;
use Digest::MD5;
use Carp qw(croak);

our $VERSION = '0.0.1';

my %ALGORITHMS = (
    MD5    => sub { Digest::MD5->new },
    SHA1   => sub { Digest::SHA->new(1) },
    SHA256 => sub { Digest::SHA->new(256) },
    SHA512 => sub { Digest::SHA->new(512) },
);

sub new {
    my ($class, %args) = @_;
    my $algo = uc($args{algorithm} // 'SHA256');
    croak "Unsupported algorithm: $algo" unless exists $ALGORITHMS{$algo};
    
    return bless {
        algorithm  => $algo,
        chunk_size => $args{chunk_size} // 65536,
        quick_hash => $args{quick_hash} // 1,
    }, $class;
}

sub hash_file {
    my ($self, $path) = @_;
    return undef unless -f $path && -r $path;
    
    open my $fh, '<:raw', $path or return undef;
    my $digest = $ALGORITHMS{$self->{algorithm}}->();
    
    while (my $bytes = read($fh, my $buffer, $self->{chunk_size})) {
        $digest->add($buffer);
    }
    close $fh;
    
    return $digest->hexdigest;
}

sub quick_hash {
    my ($self, $path) = @_;
    return undef unless -f $path && -r $path;
    
    my $size = -s $path;
    return $self->hash_file($path) if $size <= $self->{chunk_size} * 3;
    
    open my $fh, '<:raw', $path or return undef;
    my $digest = $ALGORITHMS{$self->{algorithm}}->();
    
    my $buffer;
    read($fh, $buffer, $self->{chunk_size});
    $digest->add($buffer);
    
    seek($fh, int($size / 2) - int($self->{chunk_size} / 2), 0);
    read($fh, $buffer, $self->{chunk_size});
    $digest->add($buffer);
    
    seek($fh, -$self->{chunk_size}, 2);
    read($fh, $buffer, $self->{chunk_size});
    $digest->add($buffer);
    
    close $fh;
    return 'Q:' . $digest->hexdigest;
}

sub compute {
    my ($self, $path, $quick) = @_;
    $quick //= $self->{quick_hash};
    return $quick ? $self->quick_hash($path) : $self->hash_file($path);
}

sub algorithm  { shift->{algorithm} }
sub chunk_size { shift->{chunk_size} }

sub supported_algorithms { sort keys %ALGORITHMS }

1;

=head1 NAME

DupeFinder::Hasher - File hashing utilities

=head1 SYNOPSIS

    use DupeFinder::Hasher;
    my $hasher = DupeFinder::Hasher->new(algorithm => 'SHA256');
    my $hash = $hasher->hash_file('/path/to/file');

=head1 METHODS

=over 4

=item new(%args) - Create hasher (algorithm, chunk_size, quick_hash)

=item hash_file($path) - Full file hash

=item quick_hash($path) - Partial hash for large files

=item compute($path, $quick) - Hash with mode selection

=item supported_algorithms() - List available algorithms

=back

=head1 LICENSE

Apache License 2.0

=cut
