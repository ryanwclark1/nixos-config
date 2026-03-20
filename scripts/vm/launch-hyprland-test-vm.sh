#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd -P)"
flake_ref="${FLAKE_REF:-path:${repo_root}}"
config_name="${HYPRLAND_VM_CONFIG:-hyprlandTestVm}"
state_dir="${HYPRLAND_VM_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config/hyprland-test-vm}"
disk_image="${HYPRLAND_VM_DISK_IMAGE:-}"
build_only=0
reset_disk=0
ssh_port=""
out_link=""
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
  $(basename "$0") --config hyprlandTestVm
  $(basename "$0") --disk ~/.local/state/nixos-config/hyprland-test-vm/dev.qcow2
  $(basename "$0") --reset-disk
  $(basename "$0") --ssh-port 2242
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

if [[ -n "${ssh_port}" && ! "${ssh_port}" =~ ^[0-9]+$ ]]; then
  echo "SSH port must be numeric, got: ${ssh_port}" >&2
  exit 2
fi

if [[ -z "${disk_image}" ]]; then
  if [[ -n "${ssh_port}" ]]; then
    disk_image="${state_dir}/${config_name}-${ssh_port}.qcow2"
  else
    disk_image="${state_dir}/${config_name}.qcow2"
  fi
fi

if [[ -z "${disk_image}" ]]; then
  echo "Disk image path cannot be empty" >&2
  exit 2
fi

mkdir -p "$(dirname "${disk_image}")"
disk_image="$(readlink -m "${disk_image}")"

if [[ -z "${out_link}" ]]; then
  if [[ -n "${ssh_port}" ]]; then
    out_link="${state_dir}/build-links/${config_name}-${ssh_port}"
  else
    out_link="${state_dir}/build-links/${config_name}"
  fi
fi
out_link_dir="$(dirname "${out_link}")"
out_link_name="$(basename "${out_link}")"
mkdir -p "${out_link_dir}"
out_link_dir="$(readlink -m "${out_link_dir}")"
out_link="${out_link_dir}/${out_link_name}"
if [[ -L "${out_link}" || -f "${out_link}" ]]; then
  rm -f "${out_link}"
elif [[ -e "${out_link}" ]]; then
  rm -rf "${out_link}"
fi

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
nix build --out-link "${out_link}" "${build_attr}"

runner=""
if [[ -d "${out_link}/bin" ]]; then
  for candidate in "${out_link}"/bin/run-*-vm; do
    if [[ -e "${candidate}" ]]; then
      runner="${candidate}"
      break
    fi
  done
  if [[ -z "${runner}" && -x "${out_link}/bin/run-nixos-vm" ]]; then
    runner="${out_link}/bin/run-nixos-vm"
  fi
fi

if [[ -z "${runner}" ]]; then
  echo "[ERROR] Could not find VM runner under ${out_link}/bin" >&2
  exit 1
fi

echo "[INFO] VM runner ready: ${runner}"
echo "[INFO] Using VM build link: ${out_link}"
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
