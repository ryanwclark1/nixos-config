# Command Not Found Module

This module provides intelligent command-not-found functionality using `nix-index` and the pre-built `nix-index-database`.

## Features

- **Command suggestions**: When you type a command that's not installed, it suggests which Nix package provides it
- **Pre-built database**: Uses the community-maintained database to avoid the lengthy initial indexing
- **Comma support**: Run programs without installing them using `, <program>` syntax
- **Automatic updates**: Database updates weekly from the nix-community repository

## What's Included

1. **nix-index**: The core tool that provides command-not-found functionality
2. **nix-index-database**: Pre-built database updated weekly from nix-community
3. **comma**: Run programs without installing them (e.g., `, hello` runs hello without installing)
4. **Shell integrations**: Automatic integration with bash, zsh, and fish

## Usage

### Basic Usage
When you type a command that's not found:
```bash
$ htop
The program 'htop' is not in your PATH. You can make it available in an
ephemeral shell by typing:
  nix-shell -p htop
```

### Using Comma
Run a program without installing it:
```bash
, htop  # Runs htop in a temporary nix shell
```

### Manual Database Update
While the database updates automatically weekly, you can force an update:
```bash
update-nix-index
```

## Configuration

The module is automatically imported when you include `./features/not-found` in your home configuration.

## How It Works

1. **Database Source**: Downloads pre-built database from https://github.com/nix-community/nix-index-database
2. **Location**: Database stored in `~/.cache/nix-index/`
3. **Updates**: Automatic weekly updates via the imported home-manager module
4. **Shell Hook**: Integrates with your shell's command-not-found handler

## Troubleshooting

- If command suggestions aren't working, run `update-nix-index` manually
- The database is architecture-specific (x86_64, aarch64, etc.)
- First-time setup downloads ~50MB database file