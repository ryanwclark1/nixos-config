{
  config,
  pkgs,
  lib,
  ...
}:

let
  antigravityConfig = "${config.home.homeDirectory}/.config/antigravity";
  agentDeskContext = builtins.readFile ../shared/agent-desk-context.md;
  mcpServers = lib.mapAttrs (
    _: lib.filterAttrs (_: value: value != null && value != [ ] && value != { })
  ) config.programs.mcp.servers;
in
{
  home.packages = [
    pkgs.antigravity.fhs
    pkgs.antigravity-cli
    pkgs.antigravity-ide.fhs
  ];

  home.file."${antigravityConfig}/AGENT_DESK.md".text = agentDeskContext;
  home.file."${antigravityConfig}/AGENTS.md".text = ''
    ${agentDeskContext}

    ## Antigravity Role

    Antigravity is the IDE-centric agent surface for exploratory and visual
    development work.

    Default to:

    - Coordinating with Beads for task state
    - Using WorkMux workspaces for isolated experiments
    - Keeping GitButler branches/stacks clean
    - Sharing reusable procedures through the shared skills directory
  '';
  home.file."${antigravityConfig}/mcp-servers.json".text = builtins.toJSON mcpServers;

  home.shellAliases = {
    ag = "agy";
    agy-context = "cat ${antigravityConfig}/AGENTS.md";
  };
}
