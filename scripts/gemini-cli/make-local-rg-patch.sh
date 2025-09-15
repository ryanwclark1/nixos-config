#!/usr/bin/env bash
# make-local-rg-patch.sh (robust version)
# Recreate "replace npm's ripgrep with local" for gemini-cli v0.4.1, ignoring package-lock.json

set -euo pipefail

CWD="$(pwd)"

TAG="${1:-v0.4.1}"
REPO_URL="${2:-https://github.com/google-gemini/gemini-cli.git}"
OUT="${3:-$CWD/replace-npm-rg-with-local-${TAG}.patch}"


WORKDIR="$(mktemp -d -t gemini-cli-port-XXXXXX)"
trap 'echo "Workdir: $WORKDIR"' EXIT

echo "==> Cloning $REPO_URL @ $TAG"
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$WORKDIR/repo" >/dev/null
cd "$WORKDIR/repo"

git switch -c "local-rg-${TAG}" >/dev/null
git config user.name  "Patch Porter"
git config user.email "patch.porter@example.invalid"

# ---------- JSON edits (remove @lvce-editor/ripgrep) ----------
json_del_dep () {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq 'if .dependencies then .dependencies |= del(."@lvce-editor/ripgrep") else . end' "$file" > "$tmp"
    mv "$tmp" "$file"
  else
    # Use Node if available (safer than sed for JSON)
    if command -v node >/dev/null 2>&1; then
      node -e "const fs=require('fs');const p='$file';const j=JSON.parse(fs.readFileSync(p,'utf8')); if(j.dependencies){ delete j.dependencies['@lvce-editor/ripgrep']; } fs.writeFileSync(p, JSON.stringify(j,null,2)+'\n');"
    else
      echo "ERROR: Need either jq or node to edit $file safely." >&2
      exit 1
    fi
  fi
}

echo "==> Removing '@lvce-editor/ripgrep' from package manifests"
json_del_dep "package.json"
json_del_dep "packages/core/package.json"

# ---------- TypeScript edit ----------
TS_FILE="packages/core/src/tools/ripGrep.ts"
echo "==> Updating $TS_FILE to use system 'rg'"

# 1) Drop the import line for rgPath
#    Pattern matches: import { rgPath } from '@lvce-editor/ripgrep';
grep -Ev "^import[[:space:]]*\{[[:space:]]*rgPath[[:space:]]*\}[[:space:]]*from[[:space:]]*'@lvce-editor/ripgrep'[[:space:]]*;?[[:space:]]*$" \
  "$TS_FILE" > "$TS_FILE.tmp" && mv "$TS_FILE.tmp" "$TS_FILE"

# 2) Replace spawn(rgPath, rgArgs ... ) with spawn('rg', rgArgs ... )
#    Use Perl for a reliable, quote-safe regex over the whole file.
perl -0777 -pe "s/spawn\(\s*rgPath\s*,\s*rgArgs/spawn('rg', rgArgs/g" -i "$TS_FILE"

# ---------- Commit (exclude package-lock.json) ----------
echo "==> Creating commit (excluding package-lock.json)"
git add -N package-lock.json >/dev/null || true
git add package.json packages/core/package.json "$TS_FILE"
git commit -m "replace npm's ripgrep with local (ported to ${TAG})" >/dev/null

# ---------- Emit a single patch ----------
echo "==> Writing patch to $OUT"
git format-patch -1 --stdout > "$OUT"

echo "==> Done."
echo "Patch: $OUT"
echo "Workdir (left for inspection): $WORKDIR"
