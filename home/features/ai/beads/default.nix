{ pkgs, lib, ... }:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "beads" (pkgs.beads or null))
    (llmAgents.from "beads-viewer" (pkgs.beads-viewer or null))
    (llmAgents.from "mardi-gras" (pkgs.mardi-gras or null))
  ];

  home.shellAliases = {
    bd-ready = "bd ready";
    bd-open = "bd show";
  };

  xdg.configFile."agent-desk/architecture/beads.md".text = ''
    # Beads

    Beads is the persistent work ledger for the Agent Desk workstation.

    It owns:

    - Tasks and work items
    - Dependencies and ready queues
    - Agent notes and workflow state
    - Historical decisions and project memory

    Gastown and the execution agents should treat Beads as the durable data
    plane for coordinated work.
  '';
}
