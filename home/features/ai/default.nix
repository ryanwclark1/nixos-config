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
  cleanMcpServers = lib.mapAttrs (
    _: lib.filterAttrs (_: value: value != null && value != [ ] && value != { })
  ) config.programs.mcp.servers;
in
{
  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
    ./beads
    ./claude
    # Codex is packaged from source and currently pulls in a heavy Rust/V8 build.
    # Keep it out of the default HM path so switch/rebuild stays reliable.
    # Re-enable once the package path is replaced or stabilized.
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

    # MCP and AI CLI utility scripts
    (writeShellScriptBin "mcp-cli" (builtins.readFile ./scripts/mcp-cli-launcher.sh))
    (writeShellScriptBin "mcp-process-config" (builtins.readFile ./scripts/mcp-process-config.sh))
  ];

  xdg.configFile."open-webui/mcp-servers.json".text = builtins.toJSON cleanMcpServers;

  # Environment variables for Playwright
  # These help Playwright find browsers in NixOS
  home.sessionVariables = {
    # Point to Playwright's bundled browsers (most reliable)
    PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
  };

}
