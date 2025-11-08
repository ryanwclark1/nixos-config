{
  config,
  pkgs,
  lib,
  ...
}:

let
  opencodeHome = "${config.home.homeDirectory}/opencode";
  settingsPath = "${opencodeHome}/settings.json";
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

  # home.file."${opencodeHome}/.env" = {
  #   force = true;
  #   text = ''
  #     # MCP Server Environment Variables
  #     # This file is generated at runtime by the .env-generator script
  #     CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
  #     GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
  #     SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
  #   '';
  # };

  # systemd.user.services.generate-opencode-env = {
  #   Unit = {
  #     Description = "Generate OpenCode .env file with SOPS secrets";
  #     After = [ "sops-nix.service" ];
  #     Wants = [ "sops-nix.service" ];
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = pkgs.writeShellScript "generate-opencode-env" ''
  #       #!/usr/bin/env bash
  #       # Generate .env file with actual secret values at runtime

  #       # Check if secrets exist
  #       if [ ! -f "${config.sops.secrets.context7-token.path}" ] || \
  #          [ ! -f "${config.sops.secrets.github-pat.path}" ] || \
  #          [ ! -f "${config.sops.secrets."sourcebot/api-key".path}" ]; then
  #         echo "Warning: Some SOPS secrets are not available yet" >&2
  #         exit 1
  #       fi

  #       # Generate the .env file with actual values
  #       cat > "${opencodeHome}/.env" << EOF
  #       # MCP Server Environment Variables
  #       CONTEXT7_TOKEN=$(cat "${config.sops.secrets.context7-token.path}")
  #       GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
  #       SOURCEBOT_API_KEY=$(cat "${config.sops.secrets."sourcebot/api-key".path}")
  #       EOF

  #       chmod 600 "${opencodeHome}/.env"
  #       echo "Generated .env file with actual secret values"
  #     '';
  #     RemainAfterExit = true;
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };
}
