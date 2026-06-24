{ pkgs, lib, ... }:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "gastown" (pkgs.gastown or null))
    (llmAgents.from "gascity" (pkgs.gascity or null))
    (llmAgents.from "bernstein" (pkgs.bernstein or null))
  ];

  xdg.configFile."agent-desk/architecture/gastown.md".text = ''
    # Gastown

    Gastown is the orchestration layer for the Agent Desk workstation.

    It coordinates:

    - Agent roles
    - Workflows
    - Workspaces
    - Messaging
    - Reviews

    Target flow:

    Human -> Gastown -> Specialized Agents -> Beads -> Dolt -> Git

    Beads is the task ledger. Its Dolt-backed store may be served locally
    through the Agent Desk Dolt SQL service for MySQL-compatible inspection,
    but Gastown should continue to coordinate work through Beads commands and
    workflow state.
  '';
}
