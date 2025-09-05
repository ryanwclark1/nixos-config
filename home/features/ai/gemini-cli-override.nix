{
  pkgs,
  lib,
  ...
}:

{
  # Gemini CLI Package Configuration
  #
  # STATUS: Using stable nixpkgs version (0.2.1) due to build complexity in 0.3.2
  #
  # ALTERNATIVES for version 0.3.2:
  # 1. Use gemini-cli-dev script (builds from source on-demand)
  # 2. Import ./gemini-cli-dev.nix for development version
  # 3. Manual build: npm install + npm run build in extracted source
  #
  # KNOWN ISSUES with 0.3.2:
  # - npm workspace dependencies cause cache validation failures
  # - buildNpmPackage has trouble with monorepo structure
  # - prefetch-npm-deps doesn't capture all workspace dependencies
  #
  # The nixpkgs 0.2.1 version provides core functionality and is stable
  
  home.packages = with pkgs; [
    # Stable version from nixpkgs (0.2.1)
    gemini-cli
  ];
}