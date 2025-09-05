{
  pkgs,
  lib,
  ...
}:

{
  # Development/testing version of gemini-cli 0.3.2
  # This is kept separate due to complex build requirements
  # Use: nix run .#gemini-cli-dev
  
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "gemini-cli-dev" ''
      #!/usr/bin/env bash
      
      # Development version of gemini-cli that builds from source
      # This bypasses the npm workspace caching issues
      
      set -e
      
      TEMP_DIR="/tmp/gemini-cli-dev-$$"
      VERSION="0.3.2"
      
      cleanup() {
        rm -rf "$TEMP_DIR"
      }
      trap cleanup EXIT
      
      echo "Building gemini-cli $VERSION from source..."
      
      # Download and extract source
      mkdir -p "$TEMP_DIR"
      cd "$TEMP_DIR"
      
      echo "Downloading source..."
      curl -sL "https://github.com/google-gemini/gemini-cli/archive/v$VERSION.tar.gz" | tar -xz
      cd "gemini-cli-$VERSION"
      
      echo "Installing dependencies..."
      npm install --legacy-peer-deps
      
      echo "Building project..."
      npm run build
      
      echo "Running gemini-cli $VERSION..."
      node packages/cli/dist/index.js "$@"
    '')
  ];
}