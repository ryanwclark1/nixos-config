# Knowledge Base

> **Purpose**: Accumulated insights, best practices, and troubleshooting for this NixOS configuration project.
> **Read**: When encountering issues, learning patterns, making decisions

## NixOS Best Practices

### Nix Language Patterns

#### Proper let...in Usage
```nix
# Good: Clear, scoped bindings
let
  myPackages = with pkgs; [ git vim tmux ];
  myConfig = "${config.home.homeDirectory}/.config";
in
{
  home.packages = myPackages;
  home.file."${myConfig}/example".source = ./example;
}

# Avoid: Direct inline expressions when values are reused
{
  home.packages = with pkgs; [ git vim tmux ];
  home.file."${config.home.homeDirectory}/.config/example".source = ./example;
}
```

#### Option Declarations
```nix
# Good: Well-documented options
options.programs.myfeature = {
  enable = lib.mkEnableOption "myfeature";

  package = lib.mkOption {
    type = lib.types.package;
    default = pkgs.myfeature;
    description = "The myfeature package to use";
  };

  settings = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Configuration attributes for myfeature";
  };
};
```

#### Conditional Configuration
```nix
# Good: Use mkIf for conditional blocks
config = lib.mkIf cfg.enable {
  programs.myfeature.enable = true;
  # ... rest of config
};

# Avoid: Returning empty set when disabled
config = if cfg.enable then {
  programs.myfeature.enable = true;
} else {};
```

### Home Manager Patterns

#### File Placement Strategy
```nix
# User dotfiles -> Home Manager
home.file.".bashrc".source = ./bashrc;
home.file.".config/nvim".source = ./nvim;

# System services -> NixOS
systemd.services.myservice = { ... };

# User services -> Home Manager
systemd.user.services.myservice = { ... };
```

#### Program Configuration
```nix
# Good: Use program options when available
programs.git = {
  enable = true;
  userName = "User";
  userEmail = "user@example.com";
  extraConfig = {
    init.defaultBranch = "main";
  };
};

# Avoid: Manual file writing when program options exist
home.file.".gitconfig".text = ''
  [user]
    name = User
    email = user@example.com
'';
```

### SOPS Secrets Management

#### Secret Declaration Pattern
```nix
# In secrets.yaml (encrypted)
github-pat: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]

# In configuration
sops.secrets.github-pat = {
  mode = "0400";
  owner = config.users.users.myuser.name;
};

# Usage in config
home.file.".claude/.env".text = ''
  GITHUB_PAT=$(cat ${config.sops.secrets.github-pat.path})
'';
```

#### Runtime Secret Access
- Secrets available at `/run/secrets/{name}` or paths defined in `sops.secrets.{name}.path`
- Use `${config.sops.secrets.name.path}` to reference in configs
- Never commit plaintext secrets - always encrypt with SOPS first

## Common Pitfalls & Solutions

### Issue: Infinite Recursion Error

**Cause**: Circular dependency in configuration, often from:
- Using `config` in `options` definitions
- Recursive imports between modules
- Self-referential attribute sets

**Solution**:
```nix
# Bad: Creates circular dependency
options.foo = lib.mkOption {
  default = config.bar;  # References config in options
};

# Good: Use config section for interdependencies
options.foo = lib.mkOption {
  default = null;
};
config.foo = lib.mkIf (config.foo == null) config.bar;
```

### Issue: Home Manager Symlink Collisions

**Cause**: Trying to manage same file from multiple sources

**Solution**:
```nix
# Use home.file.*.force to override
home.file.".bashrc" = {
  source = ./bashrc;
  force = true;  # Override existing file
};

# Or use priorities
home.file.".bashrc" = lib.mkDefault ./bashrc;
```

### Issue: SOPS Decryption Fails

**Cause**: Age key not available or incorrect permissions

**Solution**:
```bash
# Verify age key exists
ls -la ~/.config/sops/age/keys.txt

# Check key permissions (should be 600)
chmod 600 ~/.config/sops/age/keys.txt

# Test decryption manually
sops -d secrets/secrets.yaml

# Regenerate secret if needed
sops updatekeys secrets/secrets.yaml
```

### Issue: MCP Server Not Found

**Cause**: Missing dependencies, incorrect path, or environment variables not set

**Solution**:
```nix
# Ensure MCP server package is installed
home.packages = with pkgs; [
  # ... other packages
  nodejs  # Required for some MCP servers
];

# Check .env file has required API keys
home.file."${claudeHome}/.env".text = ''
  CONTEXT7_TOKEN=$(cat ${config.sops.secrets.context7-token.path})
'';

# Verify mcp-servers.json configuration
# Path should match installed binary location
```

### Issue: Slow Rebuild Times

**Causes & Solutions**:
1. **Too many imports**: Consolidate small modules
2. **No binary cache hits**: Check substituters in nix.conf
3. **Evaluation overhead**: Use `nix-instantiate --eval` to profile
4. **Large git repos**: Add to `.gitignore` or use `lib.cleanSource`

## Learned Patterns

### Claude Code Integration

#### Agent Auto-Activation
Agents activate based on file patterns and context:
- `*.nix` files -> nix-systems-specialist (if activated)
- Architecture discussions -> system-architect
- Code reviews -> code-reviewer
- Security concerns -> security-engineer

#### Command Usage Patterns
```bash
# Research with web search
/sc:research "latest NixOS 24.11 features" --depth standard

# Architecture design
/sc:design "Add new development environment module"

# Code analysis
/sc:analyze home/features/ai/claude/ --focus quality

# Git operations with intelligent commits
/sc:git "commit recent changes"
```

#### MCP Server Selection
- **Context7**: Documentation lookup (Nix docs, programming languages)
- **Sequential**: Complex reasoning and multi-step analysis
- **Playwright**: Web scraping and browser automation
- **Serena**: Session persistence and semantic search

### Git Workflow Patterns

#### Feature Branch Naming
```bash
# Claude Code auto-names branches with session ID
claude/{feature-description}-{session-id}

# Examples:
claude/migrate-superclause-settings-011CUy8uVwUk1LmG1DSA5yj7
claude/add-omarchy-features-011CUw3Nwc7RptSXMpZRHU48
```

#### Commit Message Style
```
Add feature description

Detailed explanation of changes:
- Specific change 1
- Specific change 2
- Why this approach was chosen

Related: Issue #123
```

### Modular Configuration Strategy

#### Feature-Based Organization
```
home/features/
├── ai/           # AI tools and configurations
│   └── claude/   # Claude Code specific
├── shell/        # Shell configurations (bash, zsh)
├── desktop/      # Desktop environment configs
├── dev/          # Development tools
└── security/     # Security tools and configs
```

Each feature is:
- **Self-contained**: All files in feature directory
- **Optional**: Can be enabled/disabled via options
- **Documented**: README.md or comments explaining purpose
- **Tested**: Verify works in isolation

## Troubleshooting Guide

### Debugging Nix Expressions

```bash
# Check flake syntax
nix flake check

# Evaluate without building
nix-instantiate --eval -E '(import ./default.nix {})'

# Show trace for errors
nix-build --show-trace

# Debug specific attribute
nix eval .#nixosConfigurations.hostname.config.programs
```

### Debugging Home Manager

```bash
# Dry run to see what would change
home-manager switch -n

# Verbose output
home-manager switch -v

# Show generated activation script
cat ~/.local/state/home-manager/gcroots/current-home/activate

# Check symlink targets
ls -la ~/.config/
```

### Debugging SOPS

```bash
# Test decryption
sops -d secrets/secrets.yaml

# Check systemd service
systemctl --user status sops-nix

# Verify secret files exist at runtime
ls -la /run/user/$(id -u)/secrets/
```

### Performance Profiling

```bash
# Rebuild timing
time nixos-rebuild switch

# Boot analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Nix evaluation time
nix-instantiate --eval --strict --show-trace 2>&1 | ts
```

## Reference Resources

### Official Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)

### Community Resources
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [Awesome Nix](https://github.com/nix-community/awesome-nix)

### Tools
- [nix-tree](https://github.com/utdemir/nix-tree) - Interactively browse dependency graphs
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) - Nix code formatter
- [statix](https://github.com/nerdypepper/statix) - Lints and suggestions for Nix
- [deadnix](https://github.com/astro/deadnix) - Find dead code in Nix

## Success Patterns

### What Works Well
- **Small, focused modules** over monolithic configurations
- **Feature flags** for optional components (mkEnableOption)
- **Centralized secrets** via SOPS with per-service access
- **Git-based versioning** with feature branches
- **Incremental testing** (rebuild test before commit)
- **Documentation alongside code** (README in feature dirs)

### What to Avoid
- Imperative changes (`nix-env`, manual file edits)
- Large inline Nix expressions (use `let...in`)
- Mixing concerns (system vs user configurations)
- Uncommitted experiments (clean up or commit)
- Updating dependencies without testing
- Hardcoded paths (use variables and config)

## Future Investigations

### Areas to Explore
- Impermanence patterns (tmpfs root filesystem)
- Declarative container management (NixOS containers)
- Cross-system synchronization strategies
- Automated testing framework for configurations
- Custom NixOS modules for complex services
- Integration with CI/CD pipelines

### Questions to Answer
- Best practices for multi-machine configuration sharing?
- Optimal caching strategy for faster rebuilds?
- How to handle machine-specific overrides elegantly?
- Testing strategies for NixOS configurations?
