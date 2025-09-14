#!/usr/bin/env bash
# port-gemini-cli-patch.sh
# Port an existing email-style patch to a new gemini-cli version and emit a new .patch
# Usage:
#   ./port-gemini-cli-patch.sh v0.4.1 /path/to/old.patch ./gemini-cli-v0.4.1-local-rg.patch
#
# Notes:
# - Uses a shallow clone of the target tag/branch.
# - Tries `git am -3` first (keeps authorship & subject). Falls back to apply/commit if needed.
# - Leaves a working tree under a temp dir for inspection (printed at the end).

set -euo pipefail

TAG="${1:?Supply target tag/branch, e.g. v0.4.1}"
PATCH_IN="${2:?Supply path to the existing .patch (email-style)}"
PATCH_OUT="${3:-gemini-cli-${TAG}-ported.patch}"

# Use the repo URL you actually used (per your log)
REPO_URL="${REPO_URL:-https://github.com/google-gemini/gemini-cli.git}"

# Make PATCH_IN absolute so it survives cd
if [[ "$PATCH_IN" != /* ]]; then
  PATCH_IN="$(cd "$(dirname "$PATCH_IN")" && pwd)/$(basename "$PATCH_IN")"
fi

WORKDIR="$(mktemp -d -t gemini-cli-port-XXXXXX)"
trap 'echo "Workdir: $WORKDIR"' EXIT

echo "==> Cloning $REPO_URL at $TAG to $WORKDIR/repo"
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$WORKDIR/repo"

cd "$WORKDIR/repo"
git config user.name  "Patch Porter"
git config user.email "patch.porter@example.invalid"

echo "==> Attempting 3-way apply with git am -3"
if git am -3 "$PATCH_IN"; then
  echo "==> git am succeeded"
else
  echo "==> git am failed; aborting and trying git apply strategies"
  git am --abort || true

  # First try a 3-way apply (uses index/BASE for context)
  if git apply --3way "$PATCH_IN"; then
    echo "==> git apply --3way succeeded"
    git add -A
    git commit -m "Port: replace npm's ripgrep with local (ported to ${TAG})"
  else
    echo "==> git apply --3way failed; trying --reject to produce .rej hunks"
    if git apply --reject "$PATCH_IN"; then
      echo "==> Patch applied with rejects; check *.rej to resolve manually"
      REJECTS=$(git ls-files -o --exclude-standard | grep -E '\.rej$' || true)
      if [[ -n "$REJECTS" ]]; then
        echo "Rejects present:"
        echo "$REJECTS"
        echo "Resolve rejects/conflicts, then:"
        echo "  git add -A"
        echo "  git commit -m 'Port local ripgrep patch to ${TAG}'"
        echo "  git format-patch -1 --stdout > '$PATCH_OUT'"
        exit 2
      fi
      git add -A
      git commit -m "Port: replace npm's ripgrep with local (ported to ${TAG})"
    else
      echo "!! Could not apply patch automatically."
      echo "   Inspect workdir: $WORKDIR/repo"
      exit 1
    fi
  fi
fi

echo "==> Emitting new patch to $PATCH_OUT"
git format-patch -1 --stdout > "$PATCH_OUT"

echo "==> Done."
echo "Patch: $PATCH_OUT"
echo "Workdir: $WORKDIR  (left for inspection)"
