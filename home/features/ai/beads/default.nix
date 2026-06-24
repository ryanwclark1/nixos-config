{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.features.agent-desk.beads.doltSqlServer;
in
{
  options.features.agent-desk.beads.doltSqlServer = {
    enable = lib.mkEnableOption "Dolt SQL server for the Agent Desk Beads repository";

    workdir = lib.mkOption {
      type = lib.types.str;
      default = "/home/administrator/nixos-config";
      description = "Repository directory containing the Beads Dolt database.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address for the Dolt MySQL-compatible SQL server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 13306;
      description = "TCP port for the Dolt MySQL-compatible SQL server.";
    };
  };

  config = {
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
      bd-sql = "mysql --protocol=tcp --host=${cfg.host} --port=${toString cfg.port} --user=root";
      bd-dolt-server = "cd ${cfg.workdir} && dolt sql-server --host ${cfg.host} --port ${toString cfg.port}";
    };

    systemd.user.services.agent-desk-dolt-sql = lib.mkIf cfg.enable {
      Unit = {
        Description = "Agent Desk Beads Dolt SQL server";
        After = [ "network.target" ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = toString cfg.workdir;
        ExecStart = "${pkgs.dolt}/bin/dolt sql-server --host ${cfg.host} --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = 5;
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
      Beads and can expose it through a MySQL-compatible SQL server for
      inspection and multi-writer access.

      Local Dolt SQL server:

      - Service: agent-desk-dolt-sql
      - Host: ${cfg.host}
      - Port: ${toString cfg.port}
      - Workdir: ${cfg.workdir}

      Useful commands:

      - bd ready
      - bd dolt status
      - bd dolt pull
      - bd dolt push
      - dolt sql-server --host ${cfg.host} --port ${toString cfg.port}
      - mysql --protocol=tcp --host=${cfg.host} --port=${toString cfg.port} --user=root

      Gastown and the execution agents should treat Beads as the durable data
      plane for coordinated work. Gastown should coordinate through Beads,
      while Dolt/MySQL access remains the persistence and inspection layer.
    '';
  };
}
