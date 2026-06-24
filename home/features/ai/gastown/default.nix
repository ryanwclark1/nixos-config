{ pkgs, lib, ... }:

let
  available = lib.filter (pkg: pkg != null);
in
{
  home.packages = available [
    (pkgs.gastown or null)
    (pkgs.gascity or null)
    (pkgs.bernstein or null)
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

    Human -> Gastown -> Specialized Agents -> Beads -> Git
  '';
}
