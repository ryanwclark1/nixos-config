# Niri Test VM

Use the local wrapper to build and launch the NixOS VM profile used for compositor testing.

See also: [NEXT_STEPS.md](/home/administrator/nixos-config/scripts/vm/NEXT_STEPS.md)

## Quick start

```bash
make niri-vm-build
make niri-vm
make niri-vm-smoke
```

The `niriTestVm` profile is configured for test access:

- SDDM is disabled
- LightDM is disabled
- tty autologin is enabled for `administrator`
- the test wrapper starts `niri.service` inside the user session when visual/runtime QA needs it
- fallback login password is `niri`
- OpenSSH is enabled, with password auth enabled for debugging
- VM host SSH keys live under `/etc/ssh` so Home Manager can manage `~/.ssh`
- VM uses a dedicated stripped-down Home Manager profile in [home/niriTestVm.nix](/home/administrator/nixos-config/home/niriTestVm.nix)
- That profile auto-launches `kitty`, masks `nm-applet` / `blueman` / `geoclue-demo-agent`, and avoids the heavier `woody` desktop extras
- VM system overrides disable `syncthing`, `blueman`, `geoclue2`, and the `niri-flake-polkit` user unit

## Disk behavior

The wrapper uses a persistent qcow2 disk by default:

- default path: `${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config/niri-test-vm/niriTestVm-<ssh-port>.qcow2`
- default VM disk size: `32G` (from `niriTestVm` profile)
- override: `NIRI_VM_DISK_IMAGE=/path/to/disk.qcow2`
- one-time override: `--disk /path/to/disk.qcow2`
- reset disk: `make niri-vm-reset` or `--reset-disk`

Per-port disks are now the default so multiple agent runs do not contend for one qcow2 image.

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

For host-side panel QA artifacts copied back from the VM:

```bash
make niri-vm-panel-qa
bash scripts/vm/run-niri-panel-qa.sh --mode settings --output-dir /tmp/panel-qa-niri-settings
```

For the unified focused regression gate across both compositor VMs:

```bash
make panel-vm-qa
bash scripts/vm/run-panel-vm-qa.sh --vm both --reset-disk
```

This runs the repo-shell panel runtime gate plus settings QA for each selected
VM, stores artifacts under
`${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config/panel-vm-qa/`, and writes
aggregate `summary.json` / `summary.md` files.

For host-side Hyprland settings QA run inside the VM:

```bash
make hyprland-vm-settings-qa
bash scripts/vm/run-hyprland-panel-qa.sh --mode settings-qa --output-dir /tmp/panel-qa-hyprland-settings-qa
```

This runs `check-settings-qa.sh --repo-shell` inside the guest and copies the
settings QA log plus first-open bar-widgets artifacts back to the host output
directory.

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

Fresh Niri test VMs authorize the host's default `~/.ssh/id_rsa`, so the normal
host-side `ssh` flow should not prompt for a password. If that key is missing,
the QA wrappers still fall back to the legacy VM password: `niri`.

## Useful launch variants

```bash
# default launch uses a headless virtio GPU so compositor QA does not open a host QEMU window
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
