{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sourcebot;
  sourcebotConfig = pkgs.writeText "sourcebot-config.json" ''
    {
      "$schema": "https://raw.githubusercontent.com/sourcebot-dev/sourcebot/main/schemas/v3/index.json",
      "connections": {
        "github": {
          "type": "github",
          "token": {
            "secret": "sourcehub_personal"
          },
          "repos": [
            "sourcebot-dev/sourcebot"
          ],
          "users": [
            "ryanwclark",
            "ryanwclark1"
          ],
          "orgs": [
            "AccentCommunications"
          ]
        }
      },
      "models": [
        {
          "provider": "openai-compatible",
          "model": "deepseek-r1:8b-0528-qwen3-q8_0",
          "displayName": "DeepSeek R1 (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "llama3.2:3b",
          "displayName": "Llama 3.2 3B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "llama3.2:8b",
          "displayName": "Llama 3.2 8B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "llama3.2:70b",
          "displayName": "Llama 3.2 70B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "codellama:7b",
          "displayName": "Code Llama 7B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "codellama:13b",
          "displayName": "Code Llama 13B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "codellama:34b",
          "displayName": "Code Llama 34B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "deepseek-coder:6.7b",
          "displayName": "DeepSeek Coder 6.7B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "deepseek-coder:33b",
          "displayName": "DeepSeek Coder 33B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "qwen3-coder:0.5b",
          "displayName": "Qwen3 Coder 0.5B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "qwen3-coder:1.5b",
          "displayName": "Qwen3 Coder 1.5B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "qwen3-coder:7b",
          "displayName": "Qwen3 Coder 7B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "qwen3-coder:14b",
          "displayName": "Qwen3 Coder 14B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "qwen3-coder:32b",
          "displayName": "Qwen3 Coder 32B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        }
      ],
      "settings": {
        "maxFileSize": 2097152,
        "maxTrigramCount": 20000,
        "reindexIntervalMs": 3600000,
        "resyncConnectionIntervalMs": 86400000,
        "resyncConnectionPollingIntervalMs": 1000,
        "reindexRepoPollingIntervalMs": 1000,
        "maxConnectionSyncJobConcurrency": 8,
        "maxRepoIndexingJobConcurrency": 8,
        "maxRepoGarbageCollectionJobConcurrency": 8,
        "repoGarbageCollectionGracePeriodMs": 10000,
        "repoIndexTimeoutMs": 7200000
      }
    }
  '';
in
{
  options.services.sourcebot = {
    enable = lib.mkEnableOption "Enable Sourcebot service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for Sourcebot web interface";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host to bind Sourcebot to";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sourcebot";
      description = "Directory to store Sourcebot data";
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to Sourcebot config file (optional)";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        AUTH_URL = "http://localhost:3002";
        CONFIG_PATH = "/data/config.json";
      };
      description = "Environment variables for Sourcebot";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add Docker to system packages
    environment.systemPackages = with pkgs; [
      docker
    ];

    # Enable Docker service
    virtualisation.docker.enable = true;

    # Create sourcebot user and group
    users.users.sourcebot = {
      isSystemUser = true;
      group = "sourcebot";
      extraGroups = [ "docker" ];
      description = "Sourcebot service user";
    };
    users.groups.sourcebot = { };

    # Create data directory
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 sourcebot sourcebot - -"
    ];

    # Sourcebot service
    systemd.services.sourcebot = {
      description = "Sourcebot Code Intelligence Platform";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "docker.service"
        "ollama.service"
      ];
      requires = [ "docker.service" ];
      wants = [ "ollama.service" ];

      serviceConfig = {
        Type = "simple";
        User = "sourcebot";
        Group = "sourcebot";
        Restart = "always";
        RestartSec = "10";
        ExecStartPre = [
          # Pull the latest image
          "${pkgs.docker}/bin/docker pull ghcr.io/sourcebot-dev/sourcebot:latest"
        ];
        ExecStart =
          let
            envArgs = lib.mapAttrsToList (name: value: "-e ${name}=${value}") cfg.environment;
          in
          lib.concatStringsSep " " (
            [
              "${pkgs.docker}/bin/docker run"
              "--rm"
              "--name sourcebot"
              "-p ${toString cfg.host}:${toString cfg.port}:3000"
              "-v ${cfg.dataDir}:/data"
              (lib.optionalString (cfg.configFile != null) "-v ${cfg.configFile}:/data/config.json:ro")
              (lib.optionalString (cfg.configFile == null) "-v ${sourcebotConfig}:/data/config.json:ro")
            ]
            ++ envArgs
            ++ [
              "ghcr.io/sourcebot-dev/sourcebot:latest"
            ]
          );
        ExecStop = "${pkgs.docker}/bin/docker stop sourcebot";
        ExecStopPost = "${pkgs.docker}/bin/docker rm sourcebot";
        TimeoutStartSec = "300";
        TimeoutStopSec = "60";
      };
    };

    # Open firewall port if enabled
    networking.firewall = lib.mkIf config.services.sourcebot.enable {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
