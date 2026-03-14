# Niri Test VM

Use the local wrapper to build and launch the NixOS VM profile used for compositor testing.

## Quick start

```bash
make niri-vm-build
make niri-vm
make niri-vm-smoke
```

The `niriTestVm` profile is configured for test access:

- SDDM autologin is enabled for `administrator`
- default session is `niri.desktop`
- tty autologin is disabled (SDDM session is the intended entrypoint)
- fallback login password is `niri`
- OpenSSH is enabled, with password auth enabled for debugging
- VM host SSH keys live under `/etc/ssh` so Home Manager can manage `~/.ssh`
- VM uses a dedicated stripped-down Home Manager profile in [home/niriTestVm.nix](/home/administrator/nixos-config/home/niriTestVm.nix)
- That profile auto-launches `kitty`, masks `nm-applet` / `blueman` / `geoclue-demo-agent`, and avoids the heavier `woody` desktop extras
- VM system overrides disable `syncthing`, `blueman`, `geoclue2`, and the `niri-flake-polkit` user unit

## Disk behavior

The wrapper uses a persistent qcow2 disk by default:

- default path: `${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config/niri-test-vm/niriTestVm.qcow2`
- default VM disk size: `16G` (from `niriTestVm` profile)
- override: `NIRI_VM_DISK_IMAGE=/path/to/disk.qcow2`
- one-time override: `--disk /path/to/disk.qcow2`
- reset disk: `make niri-vm-reset` or `--reset-disk`

If credentials look wrong, you are usually reusing an old qcow2 state. Reset it:

```bash
make niri-vm-reset
```

For a clean boot + launch in one step:

```bash
make niri-vm-fresh
```

For an automated boot-and-verify smoke check:

```bash
make niri-vm-smoke
```

## SSH debugging

Run with SSH forwarding:

```bash
make niri-vm-ssh
# or a clean disk + SSH forwarding
make niri-vm-fresh-ssh
```

Then connect from host:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 administrator@127.0.0.1
```

Password: `niri`

## Useful launch variants

```bash
# default launch already uses a virtio GL GPU and gtk display for Niri testing
make niri-vm

# pass args directly to run-*-vm
bash scripts/vm/launch-niri-test-vm.sh -- -display gtk,gl=on

# or use QEMU_OPTS directly
QEMU_OPTS='-display gtk,gl=on' make niri-vm
```

## Alternate flake/config

```bash
bash scripts/vm/launch-niri-test-vm.sh --config niriTestVm --flake .
```
