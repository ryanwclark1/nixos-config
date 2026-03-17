#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
flake_ref="${FLAKE_REF:-path:${repo_root}}"
config_name="${NIRI_VM_CONFIG:-niriTestVm}"
state_dir="${NIRI_VM_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config/niri-test-vm}"
disk_image="${NIRI_VM_DISK_IMAGE:-${state_dir}/${config_name}.qcow2}"
build_only=0
reset_disk=0
ssh_port=""
runner_args=()

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--build-only] [--config <nixosConfigurationName>] [--flake <path-or-flake-ref>]
                           [--disk <qcow2-path>] [--reset-disk] [--ssh-port <host-port>] [-- <runner-args>]

Builds and launches a NixOS VM runner from:
  nixosConfigurations.<config>.config.system.build.vm

Examples:
  $(basename "$0")
  $(basename "$0") --build-only
  $(basename "$0") --config niriTestVm
  $(basename "$0") --disk ~/.local/state/nixos-config/niri-test-vm/dev.qcow2
  $(basename "$0") --reset-disk
  $(basename "$0") --ssh-port 2222
  $(basename "$0") -- -display gtk,gl=on
  QEMU_OPTS="-display gtk,gl=on" $(basename "$0")
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-only)
      build_only=1
      shift
      ;;
    --config)
      config_name="${2:-}"
      shift 2
      ;;
    --flake)
      flake_ref="${2:-}"
      shift 2
      ;;
    --disk)
      disk_image="${2:-}"
      shift 2
      ;;
    --reset-disk)
      reset_disk=1
      shift
      ;;
    --ssh-port)
      ssh_port="${2:-}"
      shift 2
      ;;
    --)
      shift
      runner_args=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${config_name}" ]]; then
  echo "Config name cannot be empty" >&2
  exit 2
fi

if [[ -z "${disk_image}" ]]; then
  echo "Disk image path cannot be empty" >&2
  exit 2
fi

if [[ -n "${ssh_port}" && ! "${ssh_port}" =~ ^[0-9]+$ ]]; then
  echo "SSH port must be numeric, got: ${ssh_port}" >&2
  exit 2
fi

mkdir -p "$(dirname "${disk_image}")"
disk_image="$(readlink -m "${disk_image}")"

if [[ "${reset_disk}" -eq 1 && -e "${disk_image}" ]]; then
  echo "[INFO] Removing VM disk image: ${disk_image}"
  rm -f "${disk_image}"
fi

if [[ "${reset_disk}" -eq 0 && -e "${disk_image}" ]]; then
  echo "[INFO] Reusing existing VM disk image."
  echo "[INFO] If login fails, rerun with --reset-disk to clear stale credentials."
fi

build_attr="${flake_ref}#nixosConfigurations.${config_name}.config.system.build.vm"

echo "[INFO] Building VM runner: ${build_attr}"
cd "${repo_root}"
nix build "${build_attr}"

runner=""
if [[ -d "${repo_root}/result/bin" ]]; then
  for candidate in "${repo_root}"/result/bin/run-*-vm; do
    if [[ -e "${candidate}" ]]; then
      runner="${candidate}"
      break
    fi
  done
  if [[ -z "${runner}" && -x "${repo_root}/result/bin/run-nixos-vm" ]]; then
    runner="${repo_root}/result/bin/run-nixos-vm"
  fi
fi

if [[ -z "${runner}" ]]; then
  echo "[ERROR] Could not find VM runner under ${repo_root}/result/bin" >&2
  exit 1
fi

echo "[INFO] VM runner ready: ${runner}"
echo "[INFO] Using VM disk image: ${disk_image}"
if [[ "${build_only}" -eq 1 ]]; then
  echo "[INFO] Build-only mode enabled. Exiting without launch."
  exit 0
fi

qemu_opts="${QEMU_OPTS:-}"
# Use a headless virtio GPU by default so VM QA does not open a host-side QEMU
# window while still exposing a DRM-capable display to the guest compositor.
default_qemu_opts="-vga none -device virtio-vga -display none"
if [[ -z "${qemu_opts}" ]]; then
  qemu_opts="${default_qemu_opts}"
  echo "[INFO] Using default QEMU graphics options for compositor testing: ${qemu_opts}"
fi

qemu_net_opts="${QEMU_NET_OPTS:-}"
if [[ -n "${ssh_port}" ]]; then
  ssh_forward="hostfwd=tcp::${ssh_port}-:22"
  if [[ -n "${qemu_net_opts}" ]]; then
    qemu_net_opts="${qemu_net_opts},${ssh_forward}"
  else
    qemu_net_opts="${ssh_forward}"
  fi
  echo "[INFO] SSH forwarding enabled: localhost:${ssh_port} -> vm:22"
fi

echo "[INFO] Launching VM..."
exec env NIX_DISK_IMAGE="${disk_image}" QEMU_OPTS="${qemu_opts}" QEMU_NET_OPTS="${qemu_net_opts}" "${runner}" "${runner_args[@]}"
