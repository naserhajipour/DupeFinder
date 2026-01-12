# DupeFinder

Fast file deduplication and disk space analyzer for Windows, Linux and macOS.

## Description

DupeFinder scans directories to identify duplicate files using cryptographic hashes. It supports multiple hash algorithms, configurable file filters, and various actions including reporting, deleting, hardlinking, or moving duplicate files.

## Prerequisites

### Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install perl cpanminus build-essential
```

### Linux (RHEL/CentOS/Fedora)

```bash
sudo dnf install perl perl-App-cpanminus gcc make
```

### macOS

```bash
brew install perl cpanminus
```

### Windows

Download and install [Strawberry Perl](https://strawberryperl.com/) which includes cpanm.

## Installation

```bash
git clone https://github.com/muhammad-fiaz/DupeFinder.git
cd DupeFinder
cpanm --installdeps .
chmod +x bin/dupefinder
```

Add to PATH (optional):

```bash
export PATH="$PWD/bin:$PATH"
```

## Usage

### Basic Scan

```bash
./bin/dupefinder /path/to/directory
```

### Multiple Directories

```bash
./bin/dupefinder /home/user/photos /home/user/downloads
```

### Output Formats

```bash
./bin/dupefinder -f json -o report.json /data
./bin/dupefinder -f yaml -o report.yaml /data
./bin/dupefinder -f csv -o report.csv /data
```

### Filter by File Size

```bash
./bin/dupefinder -m 1024 -M 10485760 /data
```

### Filter by Extension

```bash
./bin/dupefinder -e jpg,png,gif /media/photos
```

### Delete Duplicates

```bash
# Dry run (default)
./bin/dupefinder -A delete -k first /tmp/downloads

# Execute
./bin/dupefinder -A delete -N -k first /tmp/downloads
```

### Create Hardlinks

```bash
./bin/dupefinder -A hardlink -N /data/backups
```

### Move Duplicates

```bash
./bin/dupefinder -A move -d /tmp/dupes -N /data
```

### Use Config File

```bash
./bin/dupefinder -c config/dupefinder.yaml /data
```

## Options

| Option | Description |
|--------|-------------|
| `-c, --config FILE` | Config file (YAML) |
| `-o, --output FILE` | Output file for report |
| `-f, --format FMT` | Output format: text, json, yaml, csv |
| `-v, --verbose` | Verbose output |
| `-q, --quiet` | Suppress progress messages |
| `-C, --no-color` | Disable colored output |
| `-n, --dry-run` | Dry run mode (default) |
| `-N, --no-dry-run` | Execute file operations |
| `-m, --min-size N` | Minimum file size in bytes |
| `-M, --max-size N` | Maximum file size in bytes |
| `-e, --extensions` | Comma-separated extensions |
| `-a, --algorithm` | Hash: MD5, SHA1, SHA256, SHA512 |
| `-A, --action` | Action: report, delete, hardlink, move |
| `-k, --keep` | Keep first or last file |
| `-d, --move-dir DIR` | Destination for moved duplicates |

## Running Tests

```bash
prove -l t/
```

## License

Apache License 2.0 - see [LICENSE](LICENSE)
