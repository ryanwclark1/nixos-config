{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  playwrightMcpWrapper = import ./shared/playwright-mcp-wrapper.nix { inherit pkgs lib; };
  mcpConfig = import ./shared/mcp-config.nix { inherit config pkgs lib; };
in
{
  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
    ./beads
    ./claude
    ./codex
    ./antigravity
    ./opencode
    ./gastown
    ./workmux
    ./gitbutler
    ./skills
    ./model-proxy
    ./agent-roles
  ];

  programs.mcp.enable = true;

  mcp-servers = mcpConfig;

  home.packages = with pkgs; [
    playwright
    playwright.browsers
    docker
    docker-compose

    # Wrapper script for NixOS compatibility
    playwrightMcpWrapper
  ];

  # Environment variables for Playwright
  # These help Playwright find browsers in NixOS
  home.sessionVariables = {
    # Point to Playwright's bundled browsers (most reliable)
    PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
  };

}
