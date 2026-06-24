{
  config,
  pkgs,
  lib,
  ...
}:

let
  antigravityConfig = "${config.home.homeDirectory}/.config/antigravity";
  agentDeskContext = builtins.readFile ../shared/agent-desk-context.md;
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
  mcpServers = lib.mapAttrs (
    _: lib.filterAttrs (_: value: value != null && value != [ ] && value != { })
  ) config.programs.mcp.servers;
in
{
  home.packages =
    (lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.antigravity.fhs
      (llmAgents.from "antigravity-cli" pkgs.antigravity-cli)
      pkgs.antigravity-ide.fhs
    ])
    ++ (lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.antigravity-cli
    ]);

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
