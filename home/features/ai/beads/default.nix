{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.features.agent-desk.beads;
  tunnel = cfg.remoteDoltTunnel;
  tunnelServiceName = "beads-testbox-dolt-tunnel";
in
{
  options.features.agent-desk.beads.remoteDoltTunnel = {
    enable = lib.mkEnableOption "an SSH tunnel from this machine to a remote Gas Town Dolt server";

    sshHost = lib.mkOption {
      type = lib.types.str;
      default = "testbox";
      description = "SSH host alias for the remote Gas Town host.";
    };

    localPort = lib.mkOption {
      type = lib.types.port;
      default = 3307;
      description = "Local port where Beads clients connect.";
    };

    remoteHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Remote address of the Dolt SQL server from the SSH host's perspective.";
    };

    remotePort = lib.mkOption {
      type = lib.types.port;
      default = 3307;
      description = "Remote Dolt SQL server port.";
    };
  };

  config = {
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
      bd-dolt-server =
        if tunnel.enable then "systemctl --user start ${tunnelServiceName}.service" else "gt dolt start";
      bd-dolt-status =
        if tunnel.enable then "systemctl --user status ${tunnelServiceName}.service" else "gt dolt status";
      bd-sql =
        if tunnel.enable then
          "mysql --protocol=tcp --host=127.0.0.1 --port=${toString tunnel.localPort} --user=root"
        else
          "gt dolt sql";
    };

    systemd.user.services.${tunnelServiceName} = lib.mkIf tunnel.enable {
      Unit = {
        Description = "SSH tunnel to testbox Gas Town Dolt SQL server";
        After = [ "default.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.openssh}/bin/ssh -N -L 127.0.0.1:${toString tunnel.localPort}:${tunnel.remoteHost}:${toString tunnel.remotePort} ${tunnel.sshHost} -o BatchMode=yes -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ControlMaster=no -o ControlPath=none";
        Restart = "always";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
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

      ${
        if tunnel.enable then
          ''
            On this host, Beads reaches the remote Gas Town Dolt server through
            `${tunnelServiceName}.service`, which forwards
            `127.0.0.1:${toString tunnel.localPort}` to
            `${tunnel.sshHost}:${tunnel.remoteHost}:${toString tunnel.remotePort}`.
          ''
        else
          ''
            - Lifecycle: `gt up` / `gt dolt start` / `gt dolt stop`
            - Status: `gt dolt status`
            - SQL shell: `gt dolt sql`
            - Data: ~/gt/.dolt-data/ (one database per rig + town "hq")
          ''
      }

      Useful commands:

      - bd ready
      - bd dolt status
      - bd-dolt-status
      - bd-sql

      Gas Town and the execution agents treat Beads as the durable data plane
      for coordinated work, with Dolt as the persistence and inspection layer.
    '';
  };
}
