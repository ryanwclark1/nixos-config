#!/usr/bin/env bash
# make-local-rg-patch.sh
# Recreate "replace npm's ripgrep with local" for gemini-cli v0.4.1, ignoring package-lock.json
# Usage: ./make-local-rg-patch.sh [TAG] [REPO_URL] [OUT]
#   TAG default: v0.4.1
#   REPO_URL default: https://github.com/google-gemini/gemini-cli.git
#   OUT default: ./replace-npm-rg-with-local-v0.4.1.patch

set -euo pipefail

TAG="${1:-v0.4.1}"
REPO_URL="${2:-https://github.com/google-gemini/gemini-cli.git}"
OUT="${3:-./replace-npm-rg-with-local-${TAG}.patch}"

WORKDIR="$(mktemp -d -t gemini-cli-port-XXXXXX)"
trap 'echo "Workdir: $WORKDIR"' EXIT

echo "==> Cloning $REPO_URL @ $TAG"
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$WORKDIR/repo" >/dev/null
cd "$WORKDIR/repo"

git switch -c local-rg-"$TAG" >/dev/null
git config user.name  "Patch Porter"
git config user.email "patch.porter@example.invalid"

# 1) Remove @lvce-editor/ripgrep from both package.json files
echo "==> Removing '@lvce-editor/ripgrep' from package manifests"
sed -i '/"@lvce-editor\/ripgrep":/d' package.json
sed -i '/"@lvce-editor\/ripgrep":/d' packages/core/package.json

# 2) Update the tool to use system rg instead of the npm package path
TS_FILE="packages/core/src/tools/ripGrep.ts"
echo "==> Updating $TS_FILE to use system 'rg'"
# Remove the import line (if it exists)
sed -i "s@^import { rgPath } from '@lvce-editor/ripgrep';@@g" "$TS_FILE"
# Replace spawn(rgPath, rgArgs, {...}) with spawn('rg', rgArgs, {...})
sed -i "s/spawn(rgPath, rgArgs/spawn('rg', rgArgs/g" "$TS_FILE"

# 3) Do NOT commit the lockfile change. If npm modifies it on your machine later, we keep it uncommitted.
echo "==> Creating commit (excluding package-lock.json)"
git add -N package-lock.json >/dev/null || true  # make sure it stays unstaged
git add package.json packages/core/package.json "$TS_FILE"
git commit -m "replace npm's ripgrep with local (ported to ${TAG})" >/dev/null

# 4) Emit a single-patch
echo "==> Writing patch to $OUT"
git format-patch -1 --stdout > "$OUT"

echo "==> Done."
echo "Patch: $OUT"
echo "Workdir (left for inspection): $WORKDIR"
