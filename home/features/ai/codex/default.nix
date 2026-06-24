{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  codexHome = "${config.home.homeDirectory}/.codex";
  agentDeskContext = builtins.readFile ../shared/agent-desk-context.md;
  mcpConfig = import ../shared/mcp-config.nix { inherit config pkgs lib; };
  mcpServersNix = import inputs.mcp-servers-nix { inherit pkgs; };
  codexMcpConfig = mcpServersNix.lib.mkConfig pkgs (
    mcpConfig
    // {
      flavor = "codex";
      format = "toml";
      fileName = "mcp-servers.toml";
    }
  );
in
{
  home.packages = [
    pkgs.codex
  ];

  home.file."${codexHome}/AGENT_DESK.md".text = agentDeskContext;
  home.file."${codexHome}/mcp-servers.toml".source = codexMcpConfig;
  home.file."${codexHome}/AGENTS.md" = {
    force = true;
    text = ''
      ${agentDeskContext}

      ## Codex Role

      Codex is the validation, review, and alternate-implementation agent.

      Default to:

      - Reviewing Claude/OpenCode changes for bugs and regressions
      - Producing alternate implementation strategies
      - Checking tests, type checks, builds, and stack-specific evaluations
      - Keeping edits scoped to the active Beads item or Gastown workflow stage

      Prefer direct file references, concrete commands, and small patch sets.
    '';
  };

  home.shellAliases = {
    codex-review = "codex";
  };
}
