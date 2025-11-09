# Planning & Architecture

> **Purpose**: Architecture principles, design decisions, and absolute rules for this NixOS configuration project.
> **Read**: At session start, before implementation

## Project Context

This is a **NixOS configuration repository** managing system and user configurations declaratively using:
- **NixOS**: System-level configuration and services
- **Home Manager**: User environment and dotfiles
- **Flakes**: Reproducible dependency management
- **SOPS**: Secrets management

## Architecture Principles

### 1. Declarative Everything
- All system configuration must be declarative and reproducible
- No imperative state changes (avoid `nixos-rebuild switch --upgrade`)
- All secrets managed through SOPS-nix
- Configuration changes versioned in git

### 2. Modular Organization
- Follow existing directory structure: `home/`, `hosts/`, `modules/`
- One concern per module (e.g., `home/features/ai/claude/`)
- Clear separation: system configs vs user configs vs secrets
- Reusable modules with proper option declarations

### 3. Functional Purity
- Pure Nix expressions without side effects
- Explicit dependencies (no hidden state)
- Proper use of `let...in` bindings
- Follow Nix language best practices (avoid anti-patterns)

### 4. Home Manager First
- User-level configurations belong in Home Manager
- System-level only for services requiring root
- Leverage Home Manager's activation scripts when needed

## Absolute Rules 🔴

### Nix-Specific Rules
1. **Never use imperative package installation** (`nix-env -i`) - always declarative
2. **Always validate Nix syntax** before committing (`nix flake check`)
3. **Test configurations** before pushing (rebuild on feature branch)
4. **Document custom options** with proper `mkOption` descriptions
5. **Pin dependencies** in flake.lock, update deliberately
6. **Secrets go through SOPS** - never commit plaintext credentials
7. **Follow existing patterns** - check similar configs before creating new ones

### Development Workflow Rules
1. **Feature branches only** - never work directly on main
2. **Incremental commits** - commit working states frequently
3. **Test locally first** - ensure rebuild succeeds before pushing
4. **Update flake.lock separately** - don't mix updates with features
5. **Clean up after experiments** - remove test configurations

## Design Patterns

### Configuration Structure
```
├── flake.nix                 # Entry point, inputs/outputs
├── hosts/                    # System configurations per host
│   └── {hostname}/          # Host-specific configs
├── home/                     # Home Manager configurations
│   ├── features/            # Modular feature configs
│   │   ├── ai/             # AI tools (Claude, etc.)
│   │   ├── shell/          # Shell configurations
│   │   └── desktop/        # Desktop environment
│   └── profiles/           # User profile combinations
├── modules/                  # Custom NixOS/HM modules
└── secrets/                  # SOPS encrypted secrets
```

### Module Pattern
```nix
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.myfeature;
in
{
  options.programs.myfeature = {
    enable = lib.mkEnableOption "myfeature";
    # ... other options
  };

  config = lib.mkIf cfg.enable {
    # ... implementation
  };
}
```

## Technology Decisions

### Current Stack
- **NixOS**: System configuration and package management
- **Home Manager**: User environment management
- **SOPS-nix**: Secrets management with age encryption
- **Flakes**: Dependency management and reproducibility
- **Git**: Version control

### AI/Development Tools
- **Claude Code**: Primary AI coding assistant
- **MCP Servers**: Context7, Playwright, Sequential, Serena
- **Agents**: 17 specialized agents for different domains
- **Commands**: 24 /sc: commands for workflows

## Migration Strategy

When adding new features:
1. **Research existing patterns** in the codebase
2. **Create feature branch** (`claude/feature-name-{session-id}`)
3. **Implement in modular fashion** (new module in appropriate location)
4. **Test locally** (`nixos-rebuild test` or `home-manager switch`)
5. **Commit incrementally** with clear messages
6. **Document significant changes** in commit messages
7. **Clean up** (remove debug/temporary configs)

## Risk Management

### High-Risk Operations
- Changing boot loader configuration
- Modifying filesystem mounts
- Updating kernel parameters
- Secrets management changes
- System service modifications

**Protocol**: Always test on non-production system first, maintain rollback capability

### Medium-Risk Operations
- Adding new system packages
- Modifying system services
- Changing network configuration
- Desktop environment changes

**Protocol**: Test in VM or on feature branch, verify before main merge

### Low-Risk Operations
- User-level package additions
- Shell configuration changes
- Editor settings
- Cosmetic changes

**Protocol**: Standard feature branch workflow

## Quality Standards

### Code Quality
- Follow Nix style guide (2-space indentation, proper formatting)
- Use `nixpkgs-fmt` for consistent formatting
- Proper error handling and validation
- Clear variable naming

### Documentation Quality
- Comment complex expressions
- Document custom options with descriptions
- Keep this PLANNING.md updated with major decisions
- Update KNOWLEDGE.md with learned patterns

### Testing Standards
- `nix flake check` must pass
- Local rebuild test before committing
- Verify no broken symlinks in Home Manager
- Check that secrets decrypt properly (SOPS)

## Long-term Vision

### Goals
- Fully reproducible development environment
- Seamless multi-machine synchronization
- Comprehensive AI tooling integration
- Production-ready configurations
- Zero-trust secrets management

### Non-Goals
- Supporting non-NixOS systems (focus on NixOS/HM)
- Backwards compatibility with legacy Nix (flakes-only)
- GUI configuration tools (declarative text-based only)
