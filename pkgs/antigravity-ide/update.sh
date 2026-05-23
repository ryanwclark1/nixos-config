#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch
set -eu -o pipefail

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
infoFile="$scriptDir/information.json"

# This script is a template. Antigravity IDE 2.0+ does not currently have a public update API 
# that returns the "IDE" (VS Code) specific builds separate from the Hub.
# For now, this script will help manually refresh the hashes if a new version is known.

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <version> [commit_hash]"
  echo "Example: $0 2.0.1 4861014005645312"
  exit 1
fi

version="$1"
commit="${2:-4861014005645312}"

echo "Updating Antigravity IDE to $version (Commit: $commit)..."

declare -A platforms=(
  [x86_64-linux]="linux-x64"
  [aarch64-linux]="linux-arm"
  [x86_64-darwin]="darwin-x64"
  [aarch64-darwin]="darwin-arm"
)

declare -A updates=()

for platform in "${!platforms[@]}"; do
  p="${platforms[$platform]}"
  ext="tar.gz"
  if [[ "$p" == darwin* ]]; then
    ext="zip"
  fi

  url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version}-${commit}/${p}/Antigravity%20IDE.${ext}"
  
  echo "  Prefetching $platform..."
  # Use nix-prefetch-url to get the hash
  sha256_base32=$(nix-prefetch-url "$url" --name "AntigravityIDE-${p}.${ext}" 2>/dev/null)
  sha256_hex=$(nix-hash --type sha256 --to-base16 "$sha256_base32")

  updates[$platform]="{\"url\":\"$url\",\"sha256\":\"$sha256_hex\"}"
done

echo "Updating $infoFile..."
jq -n \
  --arg ver "$version" \
  --arg vver "1.108.0" \
  --arg x64l "${updates[x86_64-linux]}" \
  --arg arml "${updates[aarch64-linux]}" \
  --arg x64d "${updates[x86_64-darwin]}" \
  --arg armd "${updates[aarch64-darwin]}" \
  '{
    version: $ver,
    vscodeVersion: $vver,
    sources: {
      "x86_64-linux": ($x64l | fromjson),
      "aarch64-linux": ($arml | fromjson),
      "x86_64-darwin": ($x64d | fromjson),
      "aarch64-darwin": ($armd | fromjson)
    }
  }' > "$infoFile"

echo "✅ Updated to $version"
