![Static Badge](https://img.shields.io/badge/%20-2e3440?style=for-the-badge&labelColor=2e3440&color=2e3440)
![Static Badge](https://img.shields.io/badge/%20-3b4252?style=for-the-badge&labelColor=3b4252&color=3b4252)
![Static Badge](https://img.shields.io/badge/%20-434c5e?style=for-the-badge&labelColor=434c5e&color=434c5e)
![Static Badge](https://img.shields.io/badge/%20-4c566a?style=for-the-badge&labelColor=4c566a&color=4c566a)
![Static Badge](https://img.shields.io/badge/%20-d8dee9?style=for-the-badge&labelColor=d8dee9&color=d8dee9)
![Static Badge](https://img.shields.io/badge/%20-e5e9f0?style=for-the-badge&labelColor=e5e9f0&color=e5e9f0)
![Static Badge](https://img.shields.io/badge/%20-eceff4?style=for-the-badge&labelColor=eceff4&color=eceff4)
![Static Badge](https://img.shields.io/badge/%20-8fbcbb?style=for-the-badge&labelColor=8fbcbb&color=8fbcbb)
![Static Badge](https://img.shields.io/badge/%20-88c0d0?style=for-the-badge&labelColor=88c0d0&color=88c0d0)
![Static Badge](https://img.shields.io/badge/%20-81a1c1?style=for-the-badge&labelColor=81a1c1&color=81a1c1)
![Static Badge](https://img.shields.io/badge/%20-5e81ac?style=for-the-badge&labelColor=5e81ac&color=5e81ac)
![Static Badge](https://img.shields.io/badge/%20-bf616a?style=for-the-badge&labelColor=bf616a&color=bf616a)
![Static Badge](https://img.shields.io/badge/%20-d08770?style=for-the-badge&labelColor=d08770&color=d08770)
![Static Badge](https://img.shields.io/badge/%20-ebcb8b?style=for-the-badge&labelColor=ebcb8b&color=ebcb8b)
![Static Badge](https://img.shields.io/badge/%20-a3be8c?style=for-the-badge&labelColor=a3be8c&color=a3be8c)
![Static Badge](https://img.shields.io/badge/%20-b48ead?style=for-the-badge&labelColor=b48ead&color=b48ead)

# NixOS and Home Manager Configurations

[![GitHub stars](https://img.shields.io/github/stars/ryanwclark1/nixos-config?color=8fbcbb&labelColor=3b4252&style=for-the-badge&logo=starship&logoColor=8fbcbb)](https://github.com/ryanwclark1/nixos-config/stargazers)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=3b4252&logo=NixOS&logoColor=81a1c1&color=81a1c1)](https://nixos.org)
[![License](https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=3b4252&colorB=5e81ac&logo=unlicense&logoColor=5e81ac)](https://github.com/ryanwclark1/nixos-config/blob/main/LICENSE)

A personal Nix flake for declarative NixOS, nix-darwin, and Home Manager configurations across desktops, laptops, servers, and test VMs. The repository is organized around reusable system modules, host-specific composition, feature-based Home Manager modules, custom packages, and operational scripts.

## Fleet

| Host | Platform | Role | Main hardware | Flake output |
| :--- | :---: | :--- | :--- | :--- |
| `woody` | NixOS | Desktop / monitoring host | Ryzen 9 7900X, 64 GB RAM, Radeon RX 7800 XT | `nixosConfigurations.woody`, `homeConfigurations.administrator@woody` |
| `frametop` | NixOS | Framework laptop | Intel i7-1260P, 64 GB RAM, Intel Iris Xe | `nixosConfigurations.frametop`, `homeConfigurations.administrator@frametop` |
| `mini` | macOS | Mac mini | Apple M4, 16 GB RAM | `darwinConfigurations.mini`, `homeConfigurations.administrator@mini` |
| `neo` | macOS | MacBook | Apple M4, 16 GB RAM | `darwinConfigurations.neo`, `homeConfigurations.ryanclark@neo` |
| `accent` | Linux | Remote server | 8 GB RAM | `homeConfigurations.administrator@accent` |
| `vlad` | Linux | Remote server | 4 GB RAM | `homeConfigurations.root@vlad` |
| `lighthouse` | Linux | Remote server | 8 GB RAM | `homeConfigurations.ryanc@lighthouse` |
| `ansible` | Linux | Automation host | Remote / VM profile | `homeConfigurations.ryanc@ansible` |
| `niriTestVm` | NixOS VM | Niri desktop test target | VM variant of `woody` | `nixosConfigurations.niriTestVm` |
| `hyprlandTestVm` | NixOS VM | Hyprland desktop test target | VM variant of `woody` | `nixosConfigurations.hyprlandTestVm` |

## Highlights

- **Modular NixOS hosts**: shared global modules, optional services, per-host hardware, and host-specific service composition under `hosts/`.
- **Feature-based Home Manager**: reusable modules for shells, editors, AI tools, desktop environments, terminals, browsers, media tools, and development stacks under `home/features/`.
- **Wayland desktop coverage**: Hyprland and Niri configurations with shared desktop services, QuickShell panel work, Stylix theming, Omarchy utilities, screenshots, clipboard helpers, and VM validation paths.
- **Development tooling**: Rust, Go, Python via `uv`, Node.js, Lua, SQL, Protobuf/gRPC, JSONnet, Nix tooling, editor integrations, and custom packages.
- **Observability**: Prometheus, Grafana, Loki, Grafana Alloy, and Alertmanager configuration primarily centered on `woody`.
- **Secrets**: SOPS and age-based secret handling through `sops-nix`.
- **Custom package overlay**: packaged AI and editor tooling including Antigravity, Claude Code, Codex, Cursor, Kiro, and supporting helpers.

## Repository Layout

| Path | Purpose |
| :--- | :--- |
| `flake.nix` | Main flake inputs, overlays, packages, dev shells, formatters, NixOS hosts, Darwin hosts, and Home Manager outputs. |
| `hosts/` | System-level NixOS and nix-darwin configuration. |
| `hosts/common/global/` | Baseline modules shared by NixOS systems. |
| `hosts/common/optional/` | Opt-in system modules for desktops, services, tools, monitoring, and virtualization. |
| `home/` | Host/user-specific Home Manager entry points. |
| `home/features/` | Reusable Home Manager feature modules. |
| `home/theme/` | Shared colors, fonts, and theme wiring. |
| `pkgs/` | Custom package definitions exposed through the flake. |
| `overlays/` | Package overlays applied to flake package sets. |
| `omarchy/` | Local Omarchy-inspired utilities, configs, themes, and install assets. |
| `scripts/` | Maintenance, package update, VM, Cursor, VS Code, and helper scripts. |
| `secrets/` | Encrypted secrets managed with SOPS. |
| `templates/` | Flake templates for C, Node.js, and Rust projects. |
| `docs/` | Focused documentation and diagrams. |

## Common Commands

Enter the development shell:

```bash
nix develop
```

Build or switch NixOS hosts:

```bash
sudo nixos-rebuild switch --flake .#woody
sudo nixos-rebuild switch --flake .#frametop
make switch i=woody
make woody
```

Build or switch nix-darwin hosts:

```bash
sudo darwin-rebuild switch --flake .#mini
sudo darwin-rebuild switch --flake .#neo
make darwin-switch i=mini
make mini
make neo
```

Apply a Home Manager configuration:

```bash
home-manager switch --flake .#administrator@woody
home-manager switch --flake .#administrator@mini
home-manager switch --flake .#ryanclark@neo
```

Maintain the flake:

```bash
make up                  # Update all flake inputs
make upp i=<input>       # Update one flake input
make fmt                 # Format Nix files
make gc                  # Clean old generations and rebuild current host for boot
make update-packages     # Run custom package updaters
make update-package-status
```

## Desktop and VM Validation

The repository includes dedicated VM workflows for compositor and panel testing.

```bash
make niri-vm
make niri-vm-smoke
make hyprland-vm
make quickshell-checks
make quickshell-test
make panel-vm-qa
make vm-disk-cleanup
```

Host-side QuickShell checks can be run without a VM:

```bash
make quickshell-guard
make quickshell-test-host
make quickshell-checks-host
```

## Secrets

Secrets are managed with SOPS and age. The helper targets can generate local SSH and age material:

```bash
make keygen
```

See [docs/secrets.md](docs/secrets.md) for the repository-specific workflow.

## Templates

Project templates are exposed from `templates/`:

```bash
nix flake init -t github:ryanwclark1/nixos-config#c
nix flake init -t github:ryanwclark1/nixos-config#node
nix flake init -t github:ryanwclark1/nixos-config#rust
```

## Documentation

- [Home Manager Guide](docs/home-manager.md)
- [Secrets Management](docs/secrets.md)
- [Hyprland Keybindings](docs/hyprland.md)
- [Package Updates](docs/package-updates.md)
- [Playwright on NixOS](docs/playwright-nixos-setup.md)
- [Screenshot Script Consolidation](docs/screenshot-scripts-consolidation.md)
- [Mini Darwin Migration](docs/mini-darwin-migration.md)
- [Configuration Diagram](docs/diagrams/nix-config.drawio)

## CI

GitHub Actions run flake health checks and QuickShell verification. Dependabot tracks GitHub Actions updates, and the lock file updater opens scheduled input refresh PRs.

## Inspirations

This configuration is influenced by [Omarchy](https://omarchy.org), [Misterio77's starter configs](https://github.com/Misterio77/nix-starter-configs), and the broader Nix community.
