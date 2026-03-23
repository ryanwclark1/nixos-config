#!/usr/bin/env bash
# Generate a small WebP thumbnail for wallpaper picker grids.
# Args: <source_image> <dest_webp_path>
# Cache key is managed by callers (qs-wallpaper-thumb wrapper).

set -euo pipefail

src="${1:-}"
dest="${2:-}"

if [[ -z "$src" || -z "$dest" ]]; then
  echo "usage: qs-wallpaper-thumb <source> <dest.webp>" >&2
  exit 2
fi

if [[ ! -f "$src" ]]; then
  echo "source not found: $src" >&2
  exit 1
fi

if [[ -f "$dest" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$dest")"
tmp="$(dirname "$dest")/.$(basename "${dest%.webp}").tmp.$$.webp"
trap 'rm -f "$tmp"' EXIT

# Scale to max 256px (Freedesktop "large" convention); WebP for size.
ffmpeg -hide_banner -loglevel error -y -i "$src" \
  -vf "scale=256:256:force_original_aspect_ratio=decrease" \
  -frames:v 1 \
  -c:v libwebp -quality 82 -f webp \
  "$tmp"

mv -f "$tmp" "$dest"
trap - EXIT
