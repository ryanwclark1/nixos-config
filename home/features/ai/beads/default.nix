{
  pkgs,
  lib,
  ...
}:

{
  # Dolt is owned and managed by Gas Town (gt), not by a standalone systemd
  # unit. Gas Town runs a single Dolt SQL server (port 3307) over
  # ~/gt/.dolt-data/, with one database per rig plus the town "hq" database,
  # and keeps it alive via `gt up` / `gt dolt`. Running a second dolt server
  # here would collide with that ownership (see `gt dolt kill-imposters`).
  #
  # This module only provides the Beads CLI and Dolt inspection tooling.

  home.packages = lib.filter (p: p != null) [
    pkgs.beads
    pkgs.beads-viewer
    pkgs.mardi-gras
    pkgs.dolt
    pkgs.mariadb.client
  ];

  home.shellAliases = {
    bd-ready = "bd ready";
    bd-open = "bd show";
    bd-sync = "bd dolt pull && bd dolt push";
    # Lifecycle and inspection go through Gas Town's managed Dolt server.
    # Delegate to `gt dolt` so the port/data dir stay owned by Gas Town
    # rather than hardcoded here.
    bd-dolt-server = "gt dolt start";
    bd-dolt-status = "gt dolt status";
    bd-sql = "gt dolt sql";
  };

  xdg.configFile."agent-desk/architecture/beads.md".text = ''
    # Beads

    Beads is the persistent work ledger for the Agent Desk workstation.

    It owns:

    - Tasks and work items
    - Dependencies and ready queues
    - Agent notes and workflow state
    - Historical decisions and project memory

    Beads is Dolt-backed. Dolt provides the versioned SQL database under
    Beads and exposes it through a MySQL-compatible SQL server for
    inspection and multi-writer access.

    ## Dolt is owned by Gas Town

    Gas Town (`gt`) manages the single Dolt SQL server, including its port
    and data directory. Do not run a second Dolt server against the same
    data; `gt dolt kill-imposters` exists precisely to evict rival servers
    from the workspace port. In particular, do not run a separate Dolt
    server (Docker compose, systemd unit, etc.) on the Gas Town port.

    - Lifecycle: `gt up` / `gt dolt start` / `gt dolt stop`
    - Status: `gt dolt status`
    - SQL shell: `gt dolt sql`
    - Data: ~/gt/.dolt-data/ (one database per rig + town "hq")

    Useful commands:

    - bd ready
    - bd dolt status
    - gt dolt status
    - gt dolt sync          # push rig databases to DoltHub remotes
    - mysql --protocol=tcp --host=127.0.0.1 --port=3307 --user=root

    Gas Town and the execution agents treat Beads as the durable data plane
    for coordinated work, with Dolt as the persistence and inspection layer.
  '';
}
