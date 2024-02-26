# Ryan's [NixOS]  & [Home Manager] Configurations

This repository contains a [Nix Flake](https://zero-to-nix.com/concepts/flakes) for configuring my computers and/or home environment.
It is not intended to be a drop in configuration for your computer, but you are welcome to use it as a reference or starting point for your own configuration.
**If you are looking for a more generic NixOS configuration, I recommend [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs).** 👍️
These computers are managed by this Nix flake ❄️

|   Hostname  |            Board            |               CPU              |  RAM  |         Primary GPU         |      Secondary GPU      | Role | OS  | State |
| :---------: | :-------------------------: | :----------------------------: | :---: | :-------------------------: | :---------------------: | :--: | :-: | :---: |
| `woody`     | [MEG-X570-UNIFY]            | [AMD Ryzen 9 7900X]            | 128GB | [RX 7800 XT]                | [AMD Ryzen 9 7900X GPU] | 🖥️   | ❄️  | ✅    |
| `frametop`  | [MEG-X570-ACE]              | [AMD Ryzen 9 5900X]            | 128GB | [Fighter RX 6700 XT]        | [NVIDIA T600]           | 🖥️   | ❄️  | ✅    |
| `steamdeck` | [Steam Deck 64GB LCD]       | Zen 2 4c/8t                    | 16GB  | 8 RDNA 2 CUs                |                         | 🎮️   | 🐧  | ✅    |
| `vm1`       | [QEMU]                      | -                              | -     | [VirGL]                     |                         | 🐄   | ❄️  | ✅    |
| `mv2`       | [QEMU]                      | -                              | -     | [VirGL]                     |                         | 🐄   | ❄️  | ✅    |
| `skull`     | [NUC6i7KYK]                 | [Intel Core i7-6770HQ]         | 64GB  | Intel Iris Pro Graphics 580 |                         | ☁️   | ❄️  | 🚧    |
| `nuc`       | [NUC5i7RYH]                 | [Intel Core i7-5557U]          | 32GB  | Intel Iris Graphics 6100    |                         | ☁️   | ❄️  | 🧟    |

**Key**

- 🎭️ : Dual boot
- 🖥️ : Desktop
- 💻️ : Laptop
- 🎮️ : Games Machine
- 🐄 : Virtual Machine
- ☁️ : Server

## Structure

- [.github]: GitHub CI/CD workflows Nix ❄️ supercharged ⚡️ by [**Determinate Systems**](https://determinate.systems)
  - [Nix Installer Action](https://github.com/marketplace/actions/the-determinate-nix-installer)
  - [Magic Nix Cache Action](https://github.com/marketplace/actions/magic-nix-cache)
  - [Flake Checker Action](https://github.com/marketplace/actions/nix-flake-checker)
  - [Update Flake Lock Action](https://github.com/marketplace/actions/update-flake-lock)
- [home-manager]: Home Manager configurations
  - Sane defaults for shell and desktop
- [nixos]: NixOS configurations
  - Includes discrete hardware configurations that leverage the [NixOS Hardware modules](https://github.com/NixOS/nixos-hardware).

The [nixos/_mixins] and [home-manager/_mixins] are a collection of composited configurations based on the arguments defined in [flake.nix].

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

## Applying Changes ✨

I clone this repo to `~/nix-config`. NixOS and Home Manager changes are applied separately because I have some non-NixOS hosts.

```bash
gh repo clone ryanwclark1/nix-config ~/nix-config
```

- ❄️ **NixOS:**  A `build-host` and `switch-host` aliases are provided that build the NixOS configuration and switch to it respectively.
- 🏠️ **Home Manager:**  A `build-home` and `switch-home` aliases are provided that build the Home Manager configuration and switch to it respectively.
- 🌍️ **All:** There are also `build-all` and `switch-all` aliases that build and switch to both the NixOS and Home Manager configurations.

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
├── home-manager
│   ├──
│   │   ├──
│   │   ├──
│   │   ├──
│   │   └──
│   └── default.nix
├── nixos
│   ├──
│   │   ├──
│   │   ├──
│   │   ├──
│   │   ├──
│   │   ├──
│   │   ├──
│   │   └──
│   ├──
│   ├──
│   ├──
│   ├──
│   └──
├── overlays
├── pkgs
├── secrets.yaml
└── flake.nix
```

The NixOS and Home Manager configurations are in the `nixos` and `home-manager` directories respectively, they are structured in the same way with `_mixins` directories that contain the mixin configurations that are used to compose the final configuration.
The `pkgs` directory contains my custom packages with package overlays in the `overlays` directory.
The `secrets.yaml` contains secrets managed by [sops-nix].
The `default.nix` files in the root of each directory are the entry points.

### The Shell 🐚

[Fish shell] with [powerline-go](https://github.com/justjanne/powerline-go) and a collection of tools that deliver a *"[Modern Unix]"* experience. The base system has a firewall enabled and also includes [OpenSSH], [sops-nix] for secret management, [ZeroTier], [Podman & Distrobox] and, of course, a delightfully configured [micro]. (*Fight me!* 🥊) My [common scripts](nixos/_mixins/scripts) are (slowly) being migrated to declarative Nix-managed scripts.

![fastfetch on Ripper](.github/screenshots/fastfetch.png)

### The Desktop 🖥️

The [font configuration] is common with both desktops using [Work Sans](https://fonts.google.com/specimen/Work+Sans) and [Fira Code](https://fonts.google.com/specimen/Fira+Code). The usual creature comforts you'd expect to find in a Linux Desktop are integrated such as [Pipewire], Bluetooth, [Avahi], [CUPS], [SANE] and [NetworkManager].

|  Desktop  |       System       |       Configuration       |             Theme            |
| :-------: | :----------------: | :-----------------------: | :--------------------------: |


![Alt](https://repobeats.axiom.co/api/embed/a82d5acf21276546e716d36dca41be774e6a5b74.svg "Repobeats analytics image")

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

- [ ] Atuin - `atuin login -u <user>`
- [ ] Brave - enroll sync
- [ ] Chatterino - authenticate
- [ ] Discord - authenticate
- [ ] GitKraken - authenticate with GitHub
- [ ] Grammarly - authenticate
- [ ] IRCCloud - authenticate
- [ ] Maelstral - `maestral_qt`
- [ ] Matrix - authenticate
- [ ] Syncthing - Connect API and introduce host
- [ ] Tailscale - `sudo tailscale up`
- [ ] Telegram - authenticate
- [ ] Keybase - `keybase login`
- [ ] VSCode - authenticate with GitHub enable sync
- [ ] Wavebox - authenticate Google and restore profile
- [ ] ZeroTier - enable host `sudo zerotier-cli info`
- [ ] Run `fonts.sh` to install commercial fonts

### Windows Boot Manager on multi-disk systems

One of my desktop (`woody`) is a multi-disk system with Windows 11 Pro installed on a separate disk from NixOS.
The Windows EFI partition is not automatically detected by systemd-boot.
The following steps are required to copy the Windows Boot Manager to the NixOS EFI partition.

Find Windows EFI Partition

```shell
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT
```

Mount Windows EFI Partition

```shell
sudo mkdir /mnt/win-efi
sudo mount /dev/nvme1n1p1 /mnt/win-efi
```

Copy Contents of Windows EFI to NixOS EFI

```shell
sudo rsync -av /mnt/win-efi/EFI/Microsoft/ /boot/EFI/Microsoft/
```

Clean up

```shell
sudo umount /mnt/win-efi
sudo rm -rf /mnt/win-efi
```

Reboot and systemd-boot should now offer the option to boot NixOS and Windows.

## TODO 🗒️

Things I should do or improve:

- [ ] Migrate Borg Backups to [borgmatic](https://torsion.org/borgmatic/) via NixOS modules and Home Manager
- [ ] Integrate [notify](https://github.com/projectdiscovery/notify)
- [ ] Integrate [homepage](https://github.com/benphelps/homepage)

### Shell

- [ ] `fzf`
- [ ] `tmate` or `tmux`
- [ ] `git-graph` and/or `git-igitt` integration

### Servers



## Inspirations 🧑‍🏫



The [Disko] implementation and automated installation are chasing the ideas outlined in these blog posts:
- [Setting up my new laptop: nix style](https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/)
- [Setting up my machines: nix style](https://aldoborrero.com/posts/2023/01/15/setting-up-my-machines-nix-style/)

[nome from Luc Perkins]: https://github.com/the-nix-way/nome
[nixos-config from Cole Helbling]: https://github.com/cole-h/nixos-config
[flake from Ana Hoverbear]: https://github.com/Hoverbear-Consulting/flake
[Declarative GNOME configuration with NixOS]: https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/
[nix-starter-configs]: (https://github.com/Misterio77/nix-starter-configs)
[Jon Seager's nixos-config]: https://github.com/jnsgruk/nixos-config
[Aaron Honeycutt's nix-configs]: https://gitlab.com/ahoneybun/nix-configs
[Matthew Croughan's nixcfg]: https://github.com/MatthewCroughan/nixcfg
[Will Taylor's dotfiles]: https://github.com/wiltaylor/dotfiles
[GitHub nixos configuration]: https://github.com/search?q=nixos+configuration
[Disko]: https://github.com/nix-community/disko

[NixOS]: https://nixos.org/
[Home Manager]: https://github.com/nix-community/home-manager

[QEMU]: https://www.qemu.org/

[VirGL]: https://docs.mesa3d.org/drivers/virgl.html

[.github]: ./github/workflows
[home-manager]: ./home-manager
[nixos]: ./nixos
[nixos/_mixins]: ./nixos/_mixins
[home-manager/_mixins]: ./home-manager/_mixins
[flake.nix]: ./flake.nix

[Fish shell]: ./nixos/default.nix
[Modern Unix]: ./home-manager/_mixins/console/default.nix
[OpenSSH]: ./nixos/_mixins/services/openssh.nix
[ZeroTier]: ./nixos/_mixins/services/zerotier.nix
[Podman & Distrobox]: ./nixos/_mixins/virt/default.nix
[micro]: [https://micro-editor.github.io/]
[sops-nix]: [https://github.com/Mic92/sops-nix]

[font configuration]: ./nixos/_mixins/desktop/default.nix
[Pipewire]: ./nixos/_mixins/services/pipewire.nix
[Avahi]: ./nixos/_mixins/services/avahi.nix
[CUPS]: ./nixos/_mixins/services/cups.nix
[SANE]: ./nixos/_mixins/services/sane.nix
[NetworkManager]: ./nixos/_mixins/services/networkmanager.nix
