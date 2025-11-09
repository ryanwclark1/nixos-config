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

# NixOS & Home Manager Configurations



[![GitHub stars](https://img.shields.io/github/stars/ryanwclark1/nixos-config?color=8fbcbb&labelColor=3b4252&style=for-the-badge&logo=starship&logoColor=8fbcbb)](https://github.com/ryanwclark1/nixos-config/stargazers)
[![GitHub repo size](https://img.shields.io/github/repo-size/ryanwclark1/nixos-config?color=88c0d0&labelColor=3b4252&style=for-the-badge&logo=github&logoColor=88c0d0)](https://github.com/ryanwclark1/nixos-config/)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=3b4252&logo=NixOS&logoColor=81a1c1&color=81a1c1)](https://nixos.org)
[![License](https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=3b4252&colorB=5e81ac&logo=unlicense&logoColor=5e81ac)](https://github.com/ryanwclark1/nixos-config/blob/main/LICENSE)



This repository contains a [Nix Flake](https://zero-to-nix.com/concepts/flakes) for configuring my computers and/or home environment.
It is not intended to be a drop in configuration for your computer, but you are welcome to use it as a reference or starting point for your own configuration.
**If you are looking for a more generic NixOS configuration, I recommend [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs).** 👍️
These computers are managed by this Nix flake ❄️

|   Hostname   |          Board           |         CPU         |  RAM  |       Primary GPU        | Role  |  OS   | State |
| :----------: | :----------------------: | :-----------------: | :---: | :----------------------: | :---: | :---: | :---: |
|   `woody`    |  [ROG-STRIX-B650E-WIFI]  | [AMD Ryzen 9 7900X] | 64GB  | [AMD Radeon RX 7800 XT]  |   🖥️   |   ❄️   |   ✅   |
|  `frametop`  | [Framework-13in-12thGen] |  [Intel i7-1260P]   | 64GB  | [Intel Iris XE Graphics] |   💻️   |   ❄️   |   ✅   |
|    `mini`    |        [Mac mini]        |     [Apple M4]      | 16GB  |  [Apple Integrated GPU]  |   🖥️   |   🍎   |   ✅   |
|   `accent`   |      Remote Server       |       Various       |  8GB  |           N/A            |   ☁️   |   ❄️   |   ✅   |
|    `vlad`    |      Remote Server       |       Various       |  4GB  |           N/A            |   ☁️   |   ❄️   |   ✅   |
| `lighthouse` |      Remote Server       |       Various       |  8GB  |           N/A            |   ☁️   |   ❄️   |   ✅   |
|  `ansible`   |      Remote Server       |       Various       |  4GB  |           N/A            |   ☁️   |   ❄️   |   ✅   |

**Key**

- 🎭️ : Dual boot
- 🖥️ : Desktop
- 💻️ : Laptop
- 🎮️ : Games Machine
- 🐄 : Virtual Machine
- ☁️ : Server

## Structure

- `home/`: Home Manager configurations accessible via `home-manager --flake`
  - `features/`: Modular feature configurations organized by category
    - `ai/`: AI tools and assistants (Claude, Gemini, Qwen, Cursor, etc.)
    - `desktop/`: Desktop environments and window managers (Hyprland, GNOME, etc.)
    - `development/`: Development tools and languages (Rust, Go, Python, etc.)
    - `shell/`: Shell configurations (Bash, Fish, Zsh, etc.)
    - `media/`: Media applications and tools
    - `productivity/`: Productivity applications
    - And many more organized feature modules
  - `global/`: Global Home Manager settings
  - `$HOST_NAME.nix`: Host-specific Home Manager configurations
- `hosts/`: NixOS system configurations accessible via `nixos-rebuild --flake`
  - `common/`: Shared configurations consumed by machine-specific ones
    - `global/`: Core system configurations applied to all machines
    - `optional/`: Opt-in configurations (desktop environments, services, tools)
    - `users/`: User account configurations
  - `$HOST_NAME/`: Machine-specific configurations with hardware support
    - Hardware configurations leveraging [NixOS Hardware modules](https://github.com/NixOS/nixos-hardware)
    - Service configurations
    - Performance optimizations
    - Monitoring setups (woody has comprehensive Grafana/Prometheus/Loki stack)
- `overlays/`: Package patches and version overrides
- `pkgs/`: Custom packages and applications
  - `code-cursor/`: Cursor IDE package
  - `kiro/`: Kiro terminal package
  - `multiviewer/`: Multiviewer package
  - `windsurf/`: Windsurf IDE package
- `templates/`: Project templates for different languages (C, Node.js, Rust)
- `scripts/`: Update scripts for custom packages
- `secrets/`: Encrypted secrets managed by [sops-nix]
- `docs/`: Documentation and configuration guides
- [flake.nix]: Entrypoint for hosts and home configurations
- [Makefile]: Commands for managing Nix, secrets, and system operations


## Installing 💾

- Boot off a .iso image created by this flake using `build-iso-desktop` or `build-iso-console` (*see below*)
- Put the .iso image on a USB drive
- Boot the target computer from the USB drive
- Two installation options are available:
  1 Use the graphical Calamares installer to install an ad-hoc system
  2 Run `install-system <hostname> <username>` from a terminal
   - The install script uses [Disko] or `disks.sh` to automatically partition and format the disks, then uses my flake via `nixos-install` to complete a full-system installation
   - This flake is copied to the target user's home directory as `~/Zero/nix-config`
   - The `nixos-enter` command is used to automatically chroot into the new system and apply the Home Manager configuration.
- Reboot 🥾


All you need is nix (any version). Run:
```
nix-shell
```

If you already have nix 2.4+, git, and have already enabled `flakes` and
`nix-command`, you can also use the non-legacy command:
```
nix develop
```

`nixos-rebuild --flake .` To build system configurations

`home-manager --flake .` To build user configurations

`nix build` (or shell or run) To build and use packages

`sops` To manage secrets

## Applying Changes ✨

I clone this repo to `~/nix-config`. NixOS and Home Manager changes are applied separately because I have some non-NixOS hosts.

```bash
gh repo clone ryanwclark1/nix-config ~/nix-config
```

### Makefile Commands

The [Makefile](Makefile) provides convenient commands for system management:

**System Management:**
- `make woody` - Switch to woody configuration
- `make switch i=<hostname>` - Switch to specified host configuration
- `make up` - Update flake inputs
- `make upp i=<input>` - Update specific flake input
- `make gc` - Garbage collect and optimize system
- `make fmt` - Format Nix files

**Key Management:**
- `make keygen` - Generate SSH and Age keys
- `make rsa_key` - Generate RSA SSH key
- `make ed25519_key` - Generate Ed25519 SSH key
- `make age_key` - Generate Age key pair
- `make get_age_public_key` - Display Age public key

**Development:**
- `make get-vscode-sha` - Get SHA256 for VSCode packages
- `make get-vscode-extension-sha` - Get SHA256 for VSCode extensions

**Dry Run:**
- `make woody-dryrun` - Dry run woody configuration
- `make frametop-dryrun` - Dry run frametop configuration

### ISO 📀

The `build-iso` script is included that creates .iso images from this flake. The following modes are available:

- `build-iso console` (*terminal environment*): Includes `install-system` for automated installation.
- `build-iso desktop` (*desktop environment*): Includes `install-system` and [Calamares](https://calamares.io/) installation.

Live images will be left in `~/$HOME/nix-config/result/iso/` and are also injected into `~/Quickemu/nixos-console` and `~/Quickemu/nixos-desktop` respectively.
The console .iso image is also periodically built and published via [GitHub [Actions](./.github/workflows) and are available in [this](https://github.com/ryanwclark1/nix-config/releases) project's Releases](https://github.com/ryanwclark1/nix-config/releases).

## What's in the box? 🎁

Nix is configured with [flake support](https://zero-to-nix.com/concepts/flakes) and the [unified CLI](https://zero-to-nix.com/concepts/nix#unified-cli) enabled.

### Structure

Here is the directory structure I'm using.

```
.
├── home/
│   ├── features/
│   │   ├── ai/                    # AI tools and assistants
│   │   │   ├── claude/            # Claude configurations
│   │   │   ├── gemini/            # Gemini configurations
│   │   │   ├── qwen/              # Qwen configurations
│   │   │   ├── cursor/            # Cursor IDE
│   │   │   └── sourcebot/         # Sourcebot AI assistant
│   │   ├── desktop/               # Desktop environments
│   │   │   ├── window-managers/   # Hyprland, Niri configurations
│   │   │   ├── environments/      # GNOME, XFCE configurations
│   │   │   └── common/            # Shared desktop components
│   │   ├── development/           # Development tools
│   │   │   ├── rust.nix          # Rust toolchain
│   │   │   ├── go.nix            # Go toolchain
│   │   │   ├── python.nix        # Python toolchain
│   │   │   └── js.nix            # JavaScript/Node.js
│   │   ├── shell/                # Shell configurations
│   │   │   ├── bash.nix
│   │   │   ├── fish.nix
│   │   │   └── zsh.nix
│   │   ├── media/                # Media applications
│   │   ├── productivity/         # Productivity tools
│   │   ├── games/                # Gaming applications
│   │   └── [many more features]
│   ├── global/                   # Global Home Manager settings
│   └── $HOST_NAME.nix           # Host-specific configurations
├── hosts/
│   ├── common/
│   │   ├── global/               # Core system configurations
│   │   ├── optional/             # Opt-in configurations
│   │   │   ├── desktop/          # Desktop environments
│   │   │   ├── services/         # System services
│   │   │   └── tools/            # System tools
│   │   └── users/                # User configurations
│   ├── frametop/                 # Framework laptop config
│   │   ├── services/             # Laptop-specific services
│   │   └── monitoring/           # Monitoring setup
│   ├── woody/                    # Desktop config
│   │   ├── services/             # Desktop-specific services
│   │   └── monitoring/            # Comprehensive monitoring stack
│   └── mini/                     # macOS config
├── overlays/                     # Package patches and overrides
├── pkgs/                         # Custom packages
│   ├── code-cursor/              # Cursor IDE
│   ├── kiro/                     # Kiro terminal
│   ├── multiviewer/              # Multiviewer
│   └── windsurf/                 # Windsurf IDE
├── templates/                    # Project templates
│   ├── c/                        # C project template
│   ├── node/                     # Node.js template
│   └── rust/                     # Rust template
├── scripts/                      # Update scripts
├── secrets/                       # Encrypted secrets
├── docs/                         # Documentation
├── flake.nix                     # Main flake configuration
└── Makefile                      # Management commands
```

The NixOS and Home Manager configurations are in the `hosts` and `home` directories respectively
The `pkgs` directory contains my custom packages with package overlays in the `overlays` directory.
The `secrets.yaml` contains secrets managed by [sops-nix].
The `default.nix` files in the root of each directory are the entry points.

### The Shell 🐚

Multiple shell configurations are supported:

- **Bash**: Traditional shell with enhanced features
- **Fish**: User-friendly shell with syntax highlighting
- **Zsh**: Powerful shell with Oh My Zsh integration
- **Ion**: Modern shell for system administration
- **NuShell**: Data-focused shell

**Shell Features:**
- Starship prompt for all shells
- FZF integration for fuzzy finding
- Zoxide for smart directory navigation
- Atuin for shell history search
- Carapace for shell completions

### AI Tools & Assistants 🤖

This configuration includes comprehensive AI tooling:

**AI Assistants:**
- **Claude**: Anthropic's Claude with MCP server integration
- **Gemini**: Google's Gemini AI with CLI tools
- **Qwen**: Alibaba's Qwen AI models
- **Sourcebot**: Custom AI assistant for code analysis

**Development Tools:**
- **Cursor**: AI-powered code editor
- **Windsurf**: Alternative AI code editor
- **Open WebUI**: Web interface for local AI models
- **Ollama**: Local AI model management

**Features:**
- MCP (Model Context Protocol) server configurations
- Docker-based AI service deployments
- Local model hosting capabilities
- Integration with development workflows

### Monitoring & Observability 📊

Comprehensive monitoring stack primarily on woody (desktop):

**Core Stack:**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and analysis
- **Grafana Alloy**: Metrics and log collection agent
- **Alertmanager**: Alert routing and management

**Monitoring Coverage:**
- System metrics (CPU, memory, disk, network)
- Container metrics (Docker, Podman)
- Application metrics
- Log analysis and correlation
- Custom dashboards for different use cases
- Multi-host monitoring capabilities

**Features:**
- Automated service discovery
- Custom alerting rules
- Log processing and filtering
- Performance optimization insights
- Security monitoring
- Network traffic analysis


### The Desktop 🖥️

This configuration supports multiple desktop environments and window managers:

**Window Managers:**
- **Hyprland**: Primary Wayland compositor with comprehensive configuration
  - Custom keybindings and workspace management (Omarchy-inspired)
  - Waybar integration with custom modules
  - Screenshot utilities and media controls
  - Mako notification daemon
  - Walker application launcher
  - 10+ custom utility scripts (keybindings-menu, workspace-toggle-gaps, etc.)
  - See [docs/hyprland.md](docs/hyprland.md) for complete keybinding reference
- **Niri**: Alternative Wayland compositor (experimental)

**Desktop Environments:**
- **GNOME**: Full GNOME desktop with extensions
- **XFCE**: Lightweight desktop environment
- **Plasma**: KDE Plasma desktop

**Browsers:**
- **Chromium**: Privacy-focused ungoogled-chromium with Wayland support
  - Hardware-accelerated video (VA-API)
  - Force dark mode
  - Privacy policies (DuckDuckGo, blocked trackers)
  - uBlock Origin + HTTPS Everywhere
  - See `home/features/chromium/README.md` for details
- **Chrome**: Google Chrome with sync support
- **Firefox**: Mozilla Firefox with Browserpass integration

**Common Features:**
- Font configuration using [Work Sans](https://fonts.google.com/specimen/Work+Sans) and [Fira Code](https://fonts.google.com/specimen/Fira+Code)
- [Pipewire] for audio management
- Bluetooth support
- [Avahi] for network discovery
- [CUPS] for printing
- [SANE] for scanner support
- [NetworkManager] for network management
- Stylix theming integration
- Catppuccin Mocha color scheme

| Desktop  |   System    |    Configuration     |        Theme         |
| :------: | :---------: | :------------------: | :------------------: |
| Hyprland |   Wayland   | Custom configuration |  Catppuccin Mocha   |
|  GNOME   | Wayland/X11 |    Standard GNOME    | Adwaita + Extensions |
|   XFCE   |     X11     |  Lightweight setup   |       Adwaita        |
|  Plasma  | X11/Wayland |      KDE Plasma      |        Breeze        |


![Alt](https://repobeats.axiom.co/api/embed/5ef4c6a66687d5e71cbe2ed39ec352a4d055aabf.svg "Repobeats analytics image")

## Post-install Checklist

Things I currently need to do manually after installation.

### Secrets

- [ ] Provision `~/.config/sops/age/keys.txt`. Optionally handled by `install-system`.
- [ ] Add `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub` to `.sops.yaml`.
- [ ] Run `sops updatekeys secrets/secrets.yaml`
- [ ] Run `gpg-restore`
- [ ] LastPass - authenticate
- [ ] Authy - activate
- [ ] 1Password - authenticate

### Services

Reboot and systemd-boot should now offer the option to boot NixOS and Windows.

## TODO 🗒️

Things I should do or improve:

### Infrastructure
- [ ] Migrate Borg Backups to [borgmatic](https://torsion.org/borgmatic/) via NixOS modules and Home Manager
- [ ] Integrate [notify](https://github.com/projectdiscovery/notify)
- [ ] Integrate [homepage](https://github.com/benphelps/homepage)
- [ ] Set up automated monitoring alerts
- [ ] Implement automated backup verification

### Development
- [ ] Add more language templates (Python, Go, Haskell)
- [ ] Improve development environment consistency across hosts
- [ ] Add more AI model integrations
- [ ] Enhance MCP server configurations

### Desktop
- [ ] Improve Niri configuration and stability
- [ ] Add more desktop environment options
- [ ] Enhance Hyprland plugin ecosystem
- [ ] Improve multi-monitor support

### Security
- [ ] Implement automated security updates
- [ ] Add intrusion detection systems
- [ ] Enhance secret management workflows
- [ ] Improve SSH key rotation automation



## Inspirations 🧑‍🏫

This configuration draws inspiration from several excellent NixOS setups and community resources:

**Configuration References:**
- [nome from Luc Perkins](https://github.com/the-nix-way/nome)
- [nixos-config from Cole Helbling](https://github.com/cole-h/nixos-config)
- [flake from Ana Hoverbear](https://github.com/Hoverbear-Consulting/flake)
- [Jon Seager's nixos-config](https://github.com/jnsgruk/nixos-config)
- [Aaron Honeycutt's nix-configs](https://gitlab.com/ahoneybun/nix-configs)
- [Matthew Croughan's nixcfg](https://github.com/MatthewCroughan/nixcfg)
- [Will Taylor's dotfiles](https://github.com/wiltaylor/dotfiles)

**Installation & Setup:**
The [Disko] implementation and automated installation are inspired by:
- [Setting up my new laptop: nix style](https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/)
- [Setting up my machines: nix style](https://aldoborrero.com/posts/2023/01/15/setting-up-my-machines-nix-style/)

**Desktop Configuration:**
- [Declarative GNOME configuration with NixOS](https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/)
- [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) - Great starting point for new users

**Community Resources:**
- [NixOS Community](https://github.com/search?q=nixos+configuration)
- [NixOS Wiki](https://nixos.wiki/)
- [Zero to Nix](https://zero-to-nix.com/)

## Links & References

**Core Technologies:**
- [NixOS](https://nixos.org/) - The Linux distribution
- [Home Manager](https://github.com/nix-community/home-manager) - User environment management
- [Disko](https://github.com/nix-community/disko) - Declarative disk partitioning
- [sops-nix](https://github.com/Mic92/sops-nix) - Secrets management

**Hardware:**
- [AMD Ryzen 9 7900X](https://www.amd.com/en/products/cpu/amd-ryzen-9-7900x)
- [Framework-13in-12thGen](https://frame.work/products/laptop-diy-12-gen-intel?q=processor)
- [Intel i7-1260P](https://www.intel.com/content/www/us/en/products/sku/226254/intel-core-i71260p-processor-18m-cache-up-to-4-70-ghz/specifications.html)
- [Intel Iris XE Graphics](https://www.intel.com/content/www/us/en/products/details/discrete-gpus/iris-xe.html)
- [ROG-STRIX-B650E-WIFI](https://rog.asus.com/us/motherboards/rog-strix/rog-strix-b650e-f-gaming-wifi-model/)
- [AMD Radeon RX 7800 XT](https://www.amd.com/en/products/graphics/amd-radeon-rx-7800-xt)
- [Mac mini](https://www.apple.com/mac-mini/)

**System Services:**
- [Pipewire](https://pipewire.org/) - Audio and video handling
- [Avahi](https://avahi.org/) - Network service discovery
- [CUPS](https://www.cups.org/) - Printing system
- [SANE](https://sane-project.org/) - Scanner access
- [NetworkManager](https://networkmanager.dev/) - Network management

---

*This configuration is actively maintained and updated. Feel free to use it as inspiration for your own NixOS setup!*
