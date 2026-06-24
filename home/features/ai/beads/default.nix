{ pkgs, lib, ... }:

let
  available = lib.filter (pkg: pkg != null);
in
{
  home.packages = available [
    pkgs.beads
    (pkgs.beads-viewer or null)
    (pkgs.mardi-gras or null)
  ];

  home.shellAliases = {
    bd-ready = "bd ready";
    bd-open = "bd show";
  };

  xdg.configFile."accent-ai/architecture/beads.md".text = ''
    # Beads

    Beads is the persistent work ledger for the Accent AI workstation.

    It owns:

    - Tasks and work items
    - Dependencies and ready queues
    - Agent notes and workflow state
    - Historical decisions and project memory

    Gastown and the execution agents should treat Beads as the durable data
    plane for coordinated work.
  '';
}
