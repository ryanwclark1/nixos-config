{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Official user-level settings & dirs (per docs)
  geminiHome = "${config.home.homeDirectory}/.gemini";
  settingsPath = "${geminiHome}/settings.json";
in
{
  programs.gemini-cli = {
    enable = true;

    # Use the automatically updated override file
    package = import ./gemini-cli-override.nix { inherit pkgs lib; };


    # JSON configuration settings
    settings = {
      theme = "Default";
      selectedAuthType = "oauth-personal";
      autoAccept = true;
      vimMode = true;
      ideMode = true;
      hasSeenIdeIntegrationNudge = true;
      # Import MCP servers configuration
      mcpServers = (builtins.fromJSON (builtins.readFile ./mcp-servers.json));
    };

    # Custom commands (if needed)
    # commands = {
    #   # Example: "mycommand" = "echo 'custom command'";
    # };
  };

  # Create .env file with secrets from SOPS
  home.file."${geminiHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
    onChange = ''
      # Expand SOPS secrets in .env file
      if [ -f "${geminiHome}/.env" ]; then
        tmp=$(${pkgs.coreutils}/bin/mktemp)
        while IFS= read -r line; do
          if [[ "$line" =~ ^([A-Z_]+)=\$\((.+)\)$ ]]; then
            var_name="''${BASH_REMATCH[1]}"
            cmd="''${BASH_REMATCH[2]}"
            value=$(eval "$cmd" 2>/dev/null || echo "")
            echo "$var_name=$value" >> "$tmp"
          else
            echo "$line" >> "$tmp"
          fi
        done < "${geminiHome}/.env"
        ${pkgs.coreutils}/bin/mv "$tmp" "${geminiHome}/.env"
      fi
    '';
  };
}
