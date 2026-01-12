requires 'perl', '5.032';

requires 'YAML::XS', '0.88';
requires 'JSON::PP', '4.0';
requires 'Digest::SHA', '6.0';
requires 'Digest::MD5', '2.58';
requires 'Term::ANSIColor', '5.0';
requires 'File::Find';
requires 'File::Copy';
requires 'File::Spec';
requires 'File::Path';
requires 'File::Basename';
requires 'Getopt::Long', '2.50';
requires 'Pod::Usage', '2.0';
requires 'Carp';
requires 'POSIX';

on 'test' => sub {
    requires 'Test::More', '1.302';
    requires 'Test::Exception', '0.43';
    requires 'File::Temp';
};
