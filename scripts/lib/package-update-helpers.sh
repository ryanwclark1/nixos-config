#!/usr/bin/env bash

get_nix_system() {
  if [[ -n "${NIX_SYSTEM:-}" ]]; then
    printf '%s\n' "$NIX_SYSTEM"
    return 0
  fi

  nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || printf 'x86_64-linux\n'
}

resolve_upstream_package_name() {
  case "$1" in
    claude-code)
      printf 'claude-code-bin\n'
      ;;
    claude-code-npm)
      printf 'claude-code\n'
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

resolve_package_update_script_json() {
  local repo_root=$1
  local pkg_name=$2
  local system=${3:-$(get_nix_system)}

  (
    nix eval --json "path:${repo_root}#packages.${system}.${pkg_name}.passthru.updateScript" 2>/dev/null
  )
}

run_package_update_script() {
  local repo_root=$1
  local pkg_name=$2
  local fallback_script=$3
  shift 3

  local system json script_type
  system=${NIX_SYSTEM:-$(get_nix_system)}

  if json=$(resolve_package_update_script_json "$repo_root" "$pkg_name" "$system"); then
    script_type=$(printf '%s' "$json" | jq -r 'type')

    case "$script_type" in
      string)
        local script_path
        script_path=$(printf '%s' "$json" | jq -r '.')
        "$script_path" "$@"
        return 0
        ;;
      array)
        local -a script_cmd=()
        mapfile -t script_cmd < <(printf '%s' "$json" | jq -r '.[]')
        "${script_cmd[@]}" "$@"
        return 0
        ;;
    esac
  fi

  if [[ -f "$fallback_script" ]]; then
    "$fallback_script" "$@"
    return 0
  fi

  echo "Error: update script not found for ${pkg_name}" >&2
  return 1
}

build_local_package_output_path() {
  local repo_root=$1
  local pkg_name=$2
  local system=${3:-$(get_nix_system)}

  nix build --print-out-paths --no-link "path:${repo_root}#packages.${system}.${pkg_name}"
}

report_upstream_derivation_diff() {
  local pkg_name=$1
  local local_file=$2
  local upstream_flake=${3:-github:NixOS/nixpkgs/nixpkgs-unstable}
  local upstream_pkg_name upstream_position upstream_file

  upstream_pkg_name=$(resolve_upstream_package_name "$pkg_name")
  upstream_position=$(nix eval --raw "${upstream_flake}#${upstream_pkg_name}.meta.position" 2>/dev/null || true)
  if [[ -z "$upstream_position" ]]; then
    echo "No upstream nixpkgs package found for ${upstream_pkg_name}."
    return 0
  fi

  upstream_file=${upstream_position%%:*}
  if [[ ! -f "$upstream_file" ]]; then
    echo "Upstream package file is not readable: $upstream_file"
    return 0
  fi

  if [[ ! -f "$local_file" ]]; then
    echo "Local package file is not readable: $local_file"
    return 0
  fi

  echo "Upstream nixpkgs package file (${upstream_pkg_name}): $upstream_file"
  if diff -u "$upstream_file" "$local_file"; then
    echo "Local package matches nixpkgs-unstable."
  else
    echo "Local package diverges from nixpkgs-unstable."
  fi
}
