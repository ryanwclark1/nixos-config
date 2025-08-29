#!/bin/sh
set -e

echo "[Custom Init] Setting up Git safe directories for mounted volumes..."

# Configure Git to allow all repositories (fixes dubious ownership issue)
git config --global --add safe.directory '*'

# Also specifically add our mounted directories
git config --global --add safe.directory /repos/nixos-config
git config --global --add safe.directory '/repos/Code/*'

echo "[Custom Init] Git configuration complete. Starting Sourcebot..."

# Execute the original entrypoint
exec /app/entrypoint.sh "$@"