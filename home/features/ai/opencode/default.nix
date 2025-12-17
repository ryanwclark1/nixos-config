{
  config,
  pkgs,
  lib,
  ...
}:

let
  opencodeHome = "${config.home.homeDirectory}/opencode";
in
{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
    # settings = {
    #   autoAccept = true;
    #   hasSeenIdeIntegrationNudge = true;
    #   ideMode = true;
    #   selectedAuthType = "oauth-personal";
    #   theme = "Default";
    #   vimMode = true;

      # Import MCP servers configuration
    #   mcpServers = (builtins.fromJSON (builtins.readFile ./mcp-servers.json));
    # };
  };

  home.file."${opencodeHome}/ollama.json" = {
    force = true;
    source = ./ollama.json;
  };
}
