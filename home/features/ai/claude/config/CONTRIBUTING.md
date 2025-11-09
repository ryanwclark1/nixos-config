# Contributing Guidelines

> **Purpose**: Contribution guidelines and workflow standards for this NixOS configuration project.
> **Read**: Before making changes or submitting pull requests

## Development Workflow

### 1. Branch Strategy

**Always use feature branches:**
```bash
# Claude Code automatically creates branches with session ID
# Format: claude/{feature-description}-{session-id}

# Examples:
git checkout -b claude/add-zsh-plugins-011CUy8uVwUk1LmG1DSA5yj7
git checkout -b claude/fix-sops-secrets-011CUw3Nwc7RptSXMpZRHU48
```

**Never commit directly to main:**
- Main branch represents stable, tested configurations
- All changes go through feature branches
- Test locally before pushing

### 2. Making Changes

**Standard workflow:**
```bash
# 1. Check current state
git status
git branch

# 2. Create feature branch (or ensure you're on one)
git checkout -b claude/your-feature-name-{session-id}

# 3. Make incremental changes
# Edit configuration files...

# 4. Test locally
nixos-rebuild test            # For system changes
home-manager switch --flake . # For user changes

# 5. Commit working state
git add -p                     # Review changes
git diff --staged             # Verify what you're committing
git commit -m "Clear description of change"

# 6. Continue or finalize
# ... more changes and commits ...

# 7. Push to remote
git push -u origin claude/your-feature-name-{session-id}
```

### 3. Commit Guidelines

**Commit messages should:**
- Start with a clear, imperative summary (50 chars max)
- Include detailed body explaining why, not just what
- Reference issues or PRs when applicable
- Be atomic (one logical change per commit)

**Good commit messages:**
```
Add Context7 MCP server configuration

- Configure Context7 for documentation lookup
- Add SOPS secret for Context7 API token
- Update mcp-servers.json with Context7 settings
- Wire up .env file with decrypted token

This enables real-time documentation lookup for libraries
and frameworks during Claude Code sessions.

Related: #45
```

**Bad commit messages:**
```
update stuff
fix
changes
wip
```

### 4. Testing Requirements

**Before committing:**

```bash
# Check Nix syntax and evaluation
nix flake check

# Test system changes (NixOS)
sudo nixos-rebuild test --flake .

# Test user changes (Home Manager)
home-manager switch --flake . -b backup

# Verify no broken symlinks
find ~ -xtype l  # Should show no broken links in managed areas
```

**Before pushing:**
```bash
# Ensure all tests pass
nix flake check

# Verify git status is clean (or intentionally dirty)
git status

# Review all changes one more time
git log --oneline -5
git diff main..HEAD
```

### 5. Pull Request Process

**Creating PRs:**
1. Push your feature branch to remote
2. Create PR from feature branch to main
3. Fill out PR template (if exists)
4. Request review (if collaborative)
5. Address feedback
6. Merge when approved and tested

**PR title format:**
```
Add {feature} / Fix {issue} / Refactor {component}

Examples:
Add Omarchy-inspired keybindings and utilities
Fix SUPER+K keybinding conflict
Refactor shebang lines for better portability
```

**PR description should include:**
- Summary of changes
- Why the changes were made
- Testing performed
- Any breaking changes
- Screenshots (if UI-related)

## Code Standards

### Nix Style Guide

**Formatting:**
- Use 2-space indentation
- Use `nixpkgs-fmt` for consistent formatting
- Maximum line length: 100 characters
- Use trailing commas in lists

```nix
# Good
{
  programs.myprogram = {
    enable = true;
    settings = {
      option1 = "value1";
      option2 = "value2";
      option3 = "value3";
    };
  };
}

# Bad - inconsistent spacing, missing commas
{
programs.myprogram={
  enable=true;
  settings={
    option1="value1";
    option2="value2"
  };
}
}
```

**Naming conventions:**
```nix
# Variables: camelCase
let
  myPackages = [ ... ];
  homeDirectory = config.home.homeDirectory;
in

# Options: kebab-case (separated by dots)
programs.my-program.enable = true;
services.my-service.auto-start = true;

# Files: kebab-case
# my-feature.nix, my-service-config.nix
```

### Module Structure

**Standard module template:**
```nix
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.myfeature;
in
{
  # 1. Options declaration
  options.programs.myfeature = {
    enable = lib.mkEnableOption "myfeature";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myfeature;
      description = "The myfeature package to use";
    };
  };

  # 2. Configuration (conditional on enable)
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # ... rest of configuration
  };
}
```

### File Organization

**Where to put files:**

```
├── home/features/{category}/{feature}/
│   ├── default.nix          # Main module definition
│   ├── config/              # Configuration files
│   │   ├── example.conf
│   │   └── settings.json
│   ├── scripts/             # Helper scripts
│   │   └── helper.sh
│   └── README.md            # Feature documentation
```

**Categories:**
- `ai/` - AI tools and assistants
- `shell/` - Shell configurations
- `desktop/` - Desktop environment configs
- `dev/` - Development tools
- `security/` - Security tools and configs

### Documentation Standards

**Every module should have:**
- Clear description in `mkEnableOption` or top-level comment
- Option descriptions for all configurable values
- README.md for complex features
- Examples in KNOWLEDGE.md for common patterns

**Example documentation:**
```nix
options.programs.myfeature = {
  enable = lib.mkEnableOption "myfeature - A tool for doing X and Y";

  configFile = lib.mkOption {
    type = lib.types.path;
    default = ./config/default.conf;
    description = ''
      Path to myfeature configuration file.

      See <link>https://example.com/docs</link> for configuration options.
    '';
    example = literalExpression "./my-custom-config.conf";
  };
};
```

## Secret Management

### Adding New Secrets

**Process:**
```bash
# 1. Edit secrets file
sops secrets/secrets.yaml

# 2. Add new secret key-value
# In editor: new-secret: "value-here"

# 3. Declare in configuration
sops.secrets.new-secret = {
  mode = "0400";
  owner = config.users.users.myuser.name;
};

# 4. Use in config (never commit plaintext!)
# Reference via: ${config.sops.secrets.new-secret.path}
```

**Secret naming convention:**
- Use kebab-case: `github-pat`, `api-key`
- Group by service: `context7/token`, `sourcebot/api-key`
- Never include 'secret' in name (redundant)

**Security rules:**
- ✅ Encrypt before committing
- ✅ Use minimal permissions (400 or 600)
- ✅ Scope to specific owner/group
- ❌ Never commit plaintext
- ❌ Never log secret values
- ❌ Never expose in error messages

## Review Checklist

**Before requesting review:**
- [ ] Code follows Nix style guide
- [ ] All options have descriptions
- [ ] Tests pass (`nix flake check`)
- [ ] Local rebuild successful
- [ ] Commit messages are clear and descriptive
- [ ] No sensitive data in commits
- [ ] Documentation updated (if needed)
- [ ] KNOWLEDGE.md updated with new patterns (if applicable)

**Reviewer checklist:**
- [ ] Changes align with PLANNING.md principles
- [ ] Code follows established patterns
- [ ] Security considerations addressed
- [ ] No performance regressions
- [ ] Documentation adequate
- [ ] Tests comprehensive

## Common Tasks

### Adding a New Package

```nix
# In home/features/{category}/default.nix
home.packages = with pkgs; [
  # ... existing packages
  new-package
];
```

### Creating a New Feature Module

```bash
# 1. Create directory structure
mkdir -p home/features/{category}/{feature}

# 2. Create default.nix
cat > home/features/{category}/{feature}/default.nix << 'EOF'
{ config, pkgs, lib, ... }:
{
  # Module contents here
}
EOF

# 3. Import in parent default.nix or flake.nix
# imports = [ ./features/{category}/{feature} ];

# 4. Document in README.md
```

### Adding a New Agent

```nix
# 1. Create agent file
# home/features/ai/claude/config/agents/my-agent.md

# 2. Add to default.nix
agents = {
  # ... existing agents
  my-agent = (builtins.readFile ./config/agents/my-agent.md);
};
```

### Adding a New /sc: Command

```nix
# 1. Create command file
# home/features/ai/claude/config/commands/sc/my-command.md

# 2. Add to default.nix
home.file."${claudeHome}/commands/sc/my-command.md" = {
  source = ./config/commands/sc/my-command.md;
};
```

## Getting Help

### Resources
- Read PLANNING.md for architecture decisions
- Check KNOWLEDGE.md for patterns and solutions
- Review existing modules for examples
- Search [NixOS Discourse](https://discourse.nixos.org/)
- Ask in #nixos IRC channel

### When Stuck
1. Check if similar pattern exists in codebase
2. Search KNOWLEDGE.md for related solutions
3. Consult NixOS/Home Manager manuals
4. Use Claude Code agents (nix-systems-specialist)
5. Ask in community forums with specific question

## Release Process

### Version Tagging
```bash
# After significant milestones
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Deployment
```bash
# For NixOS system
sudo nixos-rebuild switch --flake .

# For Home Manager
home-manager switch --flake .
```

### Rollback (if needed)
```bash
# NixOS - boot into previous generation from boot menu
# Or: sudo nixos-rebuild switch --rollback

# Home Manager
home-manager generations  # List generations
home-manager switch --switch-generation 123
```

## Best Practices Summary

**DO:**
- ✅ Use feature branches
- ✅ Test before committing
- ✅ Write clear commit messages
- ✅ Document complex logic
- ✅ Follow existing patterns
- ✅ Encrypt secrets with SOPS
- ✅ Keep commits atomic

**DON'T:**
- ❌ Commit to main directly
- ❌ Push untested changes
- ❌ Include plaintext secrets
- ❌ Mix unrelated changes in one commit
- ❌ Use imperative package management
- ❌ Skip documentation for complex features
- ❌ Leave TODO comments for core functionality
