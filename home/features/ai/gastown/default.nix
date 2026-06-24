{ pkgs, lib, ... }:

{
  home.packages = lib.filter (p: p != null) [
    pkgs.gastown
    pkgs.gascity
    pkgs.bernstein
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
