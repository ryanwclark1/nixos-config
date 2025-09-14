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

REPO_URL="${REPO_URL:-https://github.com/google-gemini/gemini-cli.git}"  # change if your upstream differs
WORKDIR="$(mktemp -d -t gemini-cli-port-XXXXXX)"
trap 'echo "Workdir: $WORKDIR"' EXIT

echo "==> Cloning $REPO_URL at $TAG to $WORKDIR/repo"
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$WORKDIR/repo"

cd "$WORKDIR/repo"

# Minimal identity so we can create a commit if we need to resolve anything
git config user.name  "Patch Porter"
git config user.email "patch.porter@example.invalid"

echo "==> Attempting 3-way apply with git am -3"
set +e
git am -3 "$PATCH_IN"
AM_STATUS=$?
set -e

if [[ $AM_STATUS -ne 0 ]]; then
  echo "==> git am failed; aborting am and attempting git apply --3way"
  git am --abort || true

  # Try to apply the patch hunks with 3-way; may leave conflict markers
  if git apply --3way --reject "$PATCH_IN"; then
    echo "==> Patch applied with git apply --3way"
    # If there are any .rej files or conflict markers, stop for manual fix.
    REJECTS=$(git ls-files -o --exclude-standard | grep -E '\.rej$' || true)
    CONFLICTS=$(git diff --name-only --diff-filter=U || true)
    if [[ -n "$REJECTS$CONFLICTS" ]]; then
      echo "!! Manual resolution required."
      echo "   Rejects:    ${REJECTS:-<none>}"
      echo "   Conflicts:  ${CONFLICTS:-<none>}"
      echo "   Resolve, then run: git add -A && git commit -m 'Port local ripgrep patch to ${TAG}'"
      echo "   Then produce patch with: git format-patch -1 --stdout > '$PATCH_OUT'"
      exit 2
    fi
    git add -A
    git commit -m "Port: replace npm's ripgrep with local (ported to ${TAG})"
  else
    echo "!! Could not apply patch automatically."
    echo "   Inspect workdir: $WORKDIR/repo"
    exit 1
  fi
else
  echo "==> git am succeeded"
fi

echo "==> Emitting new patch to $PATCH_OUT"
git format-patch -1 --stdout > "$PATCH_OUT"

echo "==> Done."
echo "Patch: $PATCH_OUT"
echo "Workdir: $WORKDIR  (left for inspection)"
