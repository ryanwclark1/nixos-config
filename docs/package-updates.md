# Package Update Guide

This document explains how to easily update the custom packages in this NixOS configuration.

## Quick Start

### Check for Updates
```bash
# Using the script directly
./scripts/update-packages.sh status

# Or using make
make update-package-status
```

### Update All Packages
```bash
# Using the script directly
./scripts/update-packages.sh update-all

# Or using make
make update-packages
```

### Update a Specific Package
```bash
./scripts/update-packages.sh update code-cursor
./scripts/update-packages.sh update cursor-cli gemini-cli
```

## Available Packages

The following packages are managed with custom versions:

1. **code-cursor** - AI-powered code editor (Cursor IDE)
2. **cursor-cli** - Cursor CLI tool
3. **gemini-cli** - Google Gemini CLI
4. **claude-code** - Anthropic Claude Code CLI
5. **codex** - OpenAI Codex CLI
6. **antigravity** - Antigravity IDE
7. **kiro** - Kiro IDE
8. **vscode-generic** - VS Code generic builder (from nixpkgs)

## Update Script Usage

The master update script (`scripts/update-packages.sh`) provides several commands:

```bash
# Check which packages have updates available
./scripts/update-packages.sh status

# List all packages with their current versions
./scripts/update-packages.sh list

# Update a specific package
./scripts/update-packages.sh update <package-name>

# Update multiple packages
./scripts/update-packages.sh update <package1> <package2>

# Update all packages
./scripts/update-packages.sh update-all
```

## Individual Package Update Scripts

Each package has its own update script in `pkgs/<package-name>/update.sh`. These scripts:

- Fetch the latest version from upstream sources
- Calculate new SHA256 hashes for all platforms
- Update the package definition files automatically
- Show a git diff of changes for review

### Running Individual Updates

You can also run individual update scripts directly:

```bash
cd pkgs/code-cursor && ./update.sh
cd pkgs/cursor-cli && ./update.sh
# etc.
```

## Post-Update Steps

After updating packages, you may need to:

1. **Review changes**: Check the git diff to see what was updated
   ```bash
   git diff pkgs/<package-name>/
   ```

2. **For npm packages** (gemini-cli, claude-code): Update `npmDepsHash`
   ```bash
   nix build .#<package-name>
   # Copy the hash from the error message and update default.nix
   ```

3. **For Rust packages** (codex): Update `cargoHash`
   ```bash
   nix build .#codex
   # Copy the hash from the error message and update default.nix
   ```

4. **Test the build**: Ensure the package builds correctly
   ```bash
   nix build .#<package-name>
   ```

5. **Rebuild your system**: Apply the updates
   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

## Automation

### Weekly Update Check

You can add a cron job or systemd timer to check for updates weekly:

```bash
# Add to crontab
0 0 * * 0 cd /path/to/nixos-config && ./scripts/update-packages.sh status
```

### Git Hooks

You could also set up a git hook to remind you to update packages before committing, though this is optional.

## Troubleshooting

### Update Script Fails

If an update script fails:

1. Check the error message - it usually indicates what went wrong
2. Verify network connectivity
3. Check if the upstream source has changed its API/structure
4. Manually inspect the package's update script in `pkgs/<package>/update.sh`

### Hash Mismatch

If you get hash mismatches:

1. The update script should handle this automatically
2. If not, manually run `nix-prefetch-url <url>` to get the correct hash
3. Update the hash in the package's `default.nix` or `sources.json`

### Build Failures After Update

If a package fails to build after updating:

1. Check if dependencies have changed
2. Review the build error messages
3. Compare with the nixpkgs version to see if there are new requirements
4. Check the package's GitHub issues or changelog for breaking changes

## Package-Specific Notes

### code-cursor
- Uses Cursor's API to fetch latest versions
- Supports Linux (x86_64, ARM64) and Darwin (x86_64, ARM64)

### cursor-cli
- Fetches from Cursor's install page
- Version format: `0-unstable-YYYY-MM-DD`

### gemini-cli
- Requires manual `npmDepsHash` update after version bump
- Fetches from GitHub releases

### claude-code
- Requires manual `npmDepsHash` update after version bump
- Also updates `package-lock.json` automatically
- Fetches from npm registry

### codex
- Requires manual `cargoHash` update after version bump
- Fetches from GitHub releases (tags prefixed with `rust-v`)

### antigravity
- Uses `information.json` for version tracking
- Fetches from Antigravity's update API

### kiro
- Uses `sources.json` for version tracking
- Fetches from Kiro's metadata API
- Automatically extracts VSCode version from package

