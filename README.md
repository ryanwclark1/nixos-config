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

# ❄️ NixOS & Home Manager Configurations

[![GitHub stars](https://img.shields.io/github/stars/ryanwclark1/nixos-config?color=8fbcbb&labelColor=3b4252&style=for-the-badge&logo=starship&logoColor=8fbcbb)](https://github.com/ryanwclark1/nixos-config/stargazers)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=3b4252&logo=NixOS&logoColor=81a1c1&color=81a1c1)](https://nixos.org)
[![License](https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=3b4252&colorB=5e81ac&logo=unlicense&logoColor=5e81ac)](https://github.com/ryanwclark1/nixos-config/blob/main/LICENSE)

A comprehensive, modular [Nix Flake](https://zero-to-nix.com/concepts/flakes) for managing a multi-host fleet across Linux (NixOS) and macOS (nix-darwin).

## 🖥️ Fleet Overview

| Hostname | Platform | Role | CPU | RAM | Primary GPU | Status |
| :--- | :---: | :---: | :--- | :---: | :--- | :---: |
| `woody` | ❄️ | 🖥️ | [AMD Ryzen 9 7900X] | 64GB | [AMD Radeon RX 7800 XT] | ✅ |
| `neo` | 🍎 | 💻️ | [Apple M4] | 16GB | [Apple Integrated GPU] | ✅ |
| `mini` | 🍎 | 🖥️ | [Apple M4] | 16GB | [Apple Integrated GPU] | ✅ |
| `frametop` | ❄️ | 💻️ | [Intel i7-1260P] | 64GB | [Intel Iris XE Graphics] | ✅ |
| `accent` | ❄️ | ☁️ | Remote Server | 8GB | N/A | ✅ |
| `vlad` | ❄️ | ☁️ | Remote Server | 4GB | N/A | ✅ |
| `lighthouse`| ❄️ | ☁️ | Remote Server | 8GB | N/A | ✅ |

**Key:** 🖥️ Desktop • 💻️ Laptop • ☁️ Server • 🍎 macOS • ❄️ NixOS

---

## 🚀 Key Features

### 🤖 SuperClaude Framework
An elite AI development ecosystem integrated directly into the workspace.
- **20 Specialized Agents**: Tailored personas for everything from Nix systems to Security engineering.
- **Knowledge Management**: Structured `PLANNING.md`, `TASK.md`, and `KNOWLEDGE.md` for continuous learning.
- **MCP Integration**: Model Context Protocol servers for Context7, Playwright, and Sequential Thinking.
- **Multi-Assistant Support**: Deeply configured setups for Claude, Gemini, Codex, and local Ollama models.

### 📊 Observability Stack
Production-grade monitoring primarily hosted on `woody`:
- **Metrics**: Prometheus & Grafana for system-wide performance tracking.
- **Logging**: Loki for centralized log aggregation.
- **Agents**: Grafana Alloy for telemetry collection.
- **Alerting**: Alertmanager for proactive system health notifications.

### 🎨 The Desktop Experience
Modern, high-performance Wayland environments:
- **Hyprland & Niri**: Fully declarative Wayland compositors.
- **Omarchy Integration**: DHH-inspired system utilities (`os-battery-show`, `os-time-show`).
- **Stylix**: Unified theming across applications using the Nord color palette.
- **Custom Scripts**: Unified `screenshot.sh` and clipboard management.

### 🛠️ Development Environments
Isolated, reproducible toolchains for modern engineering:
- **Languages**: Rust, Go, Python (via `uv`), Node.js, Lua, SQL.
- **Tooling**: Protobuf/gRPC suite, JSONnet, and advanced system debuggers.
- **IDEs**: Declarative configurations for Cursor, VS Code, and Ghostty.

---

## 🏗️ Repository Structure

- `home/`: Home Manager modules and host-specific user configs.
  - `features/`: Modular features (AI, Shell, Development, Desktop, etc.)
  - `global/`: Shared user settings.
- `hosts/`: System-level configurations (NixOS and nix-darwin).
  - `common/`: Shared system traits and optional service modules.
- `pkgs/`: Custom packages and builders (antigravity, claude-code, gemini-cli, etc.).
- `omarchy/`: Custom bin utilities and distribution logic.
- `scripts/`: Maintenance and update scripts.
- `secrets/`: Encrypted secrets managed via `sops-nix`.

---

## 🛠️ Usage

### Quick Start
```bash
# Enter the development shell
nix develop # or nix-shell

# Apply NixOS configuration
sudo nixos-rebuild switch --flake .#<hostname>

# Apply Home Manager configuration
home-manager switch --flake .#<user>@<host>

# Apply Darwin configuration
darwin-rebuild switch --flake .#<hostname>
```

### Management via Makefile
- `make switch i=<host>`: Rebuild specific host.
- `make woody`: Rebuild the primary desktop.
- `make up`: Update all flake inputs.
- `make gc`: Perform system cleanup and garbage collection.
- `make fmt`: Format all Nix files in the repository.

---

## 📜 Documentation
- [Home Manager Guide](docs/home-manager.md)
- [Secrets Management](docs/secrets.md)
- [Hyprland Keybindings](docs/hyprland.md)
- [Screenshot Consolidation](docs/screenshot-scripts-consolidation.md)

---

## 🧑‍🏫 Inspirations
Heavily influenced by [Omarchy](https://omarchy.org), [Misterio77's starter configs](https://github.com/Misterio77/nix-starter-configs), and the Nix community's best practices.

*Generated with ❤️ by Gemini CLI*
