{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.features.agent-desk.gastown;
in
{
  options.features.agent-desk.gastown = {
    hqRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/gt";
      description = "Path to the Gas Town HQ workspace.";
    };

    autoStartDolt = lib.mkEnableOption "starting Gas Town's Dolt SQL server on login";

    doltPort = lib.mkOption {
      type = lib.types.port;
      default = 3317;
      description = "Port for Gas Town's Dolt SQL server.";
    };
  };

  config = {
    home.packages = lib.filter (p: p != null) [
      pkgs.gastown
      pkgs.gascity
      pkgs.bernstein
    ];

    # Let `gt` locate the HQ workspace from any shell (not just tmux panes,
    # where the daemon injects it). Without this, `gt` invoked from a plain
    # shell or a project checkout fails with "not in a Gas Town workspace".
    home.sessionVariables.GT_TOWN_ROOT = cfg.hqRoot;

    # Persist Gas Town's Dolt SQL server (the Beads data plane) across
    # reboots. This runs `gt dolt start` from the HQ, so it picks up the
    # HQ's configured port and data directory automatically. Only the Dolt
    # server is started here; the daemon/mayor/witnesses (which spawn agent
    # sessions) are left to an explicit `gt up`.
    systemd.user.services.gastown-dolt = lib.mkIf cfg.autoStartDolt {
      Unit = {
        Description = "Gas Town Dolt SQL server (Beads data plane)";
        After = [ "default.target" ];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = cfg.hqRoot;
        Environment = [
          "GT_DOLT_PORT=${toString cfg.doltPort}"
          "PATH=${
            lib.makeBinPath [
              pkgs.gastown
              pkgs.dolt
              pkgs.beads
              pkgs.git
              pkgs.bash
              pkgs.coreutils
            ]
          }"
        ];
        ExecStart = "${pkgs.gastown}/bin/gt dolt start";
        ExecStop = "${pkgs.gastown}/bin/gt dolt stop";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

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

      Beads is the task ledger. Gas Town owns the Dolt SQL server that backs
      it (`gt dolt`); the `gastown-dolt` user service keeps that server
      running across reboots on port ${toString cfg.doltPort}. Gastown
      coordinates work through Beads commands and workflow state on top of it.
    '';
  };
}
