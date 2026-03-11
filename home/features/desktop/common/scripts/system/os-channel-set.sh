#!/usr/bin/env bash

set -euo pipefail

FLAKE_DIR="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"

if (($# == 0)); then
  echo "Usage: os-channel-set {stable|update}" >&2
  exit 1
fi

case "$1" in
  stable)
    nixos-rebuild switch --flake "$FLAKE_DIR"
    ;;
  update)
    nix flake update --flake "$FLAKE_DIR" && nixos-rebuild switch --flake "$FLAKE_DIR"
    ;;
  *)
    echo "Usage: os-channel-set {stable|update}" >&2
    exit 1
    ;;
esac
