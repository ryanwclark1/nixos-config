{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Official user-level settings & dirs (per docs)
  codexHome = "${config.home.homeDirectory}/.codex";
  settingsPath = "${codexHome}/settings.json";
in
{
  programs.codex = {
    enable  = true;

    package = pkgs.codex;  # Change if
    settings = {

      mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);
    };
    # custom-instructions = {
    #   # Example custom instruction
    #   "Always use markdown for code snippets" = "Whenever you provide code, format it using markdown code blocks with the appropriate language specified. This ensures proper syntax highlighting and readability.";
    # };

  };

  # Create .env file with secrets from SOPS
  home.file."${codexHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
    onChange = ''
      # Expand SOPS secrets in .env file
      if [ -f "${codexHome}/.env" ]; then
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
        done < "${codexHome}/.env"
        ${pkgs.coreutils}/bin/mv "$tmp" "${codexHome}/.env"
      fi
    '';
  };
}
