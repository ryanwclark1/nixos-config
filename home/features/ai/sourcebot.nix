{
  config,
  lib,
  pkgs,
  ...
}:

let
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
          "model": "deepseek-r1:8b",
          "displayName": "DeepSeek R1 8B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible", 
          "model": "qwen3-coder:30b",
          "displayName": "Qwen3 Coder 30B (Ollama)",
          "baseUrl": "http://localhost:11434/v1"
        },
        {
          "provider": "openai-compatible",
          "model": "gpt-oss:latest", 
          "displayName": "GPT OSS (Ollama)",
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
  # Add Docker and related packages
  home.packages = with pkgs; [
    docker
  ];

  # Create Sourcebot configuration directory
  home.file.".config/sourcebot/config.json".source = sourcebotConfig;

  # Create Sourcebot data directory
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/sourcebot 0755 - - - -"
  ];

  # Sourcebot user service
  systemd.user.services.sourcebot = {
    Unit = {
      Description = "Sourcebot Code Intelligence Platform";
      After = [ "network.target" ];
      Wants = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10";
      TimeoutStartSec = "300";
      TimeoutStopSec = "60";
      
      ExecStartPre = [
        "${pkgs.docker}/bin/docker pull ghcr.io/sourcebot-dev/sourcebot:latest"
        "${pkgs.writeShellScript "cleanup-sourcebot" ''
          ${pkgs.docker}/bin/docker stop sourcebot 2>/dev/null || true
          ${pkgs.docker}/bin/docker rm sourcebot 2>/dev/null || true
        ''}"
      ];
      
      ExecStart = "${pkgs.writeShellScript "start-sourcebot" ''
        exec ${pkgs.docker}/bin/docker run \
          --rm \
          --name sourcebot \
          -p 127.0.0.1:3002:3000 \
          -v ${config.home.homeDirectory}/.local/share/sourcebot:/data \
          -v ${config.home.homeDirectory}/.config/sourcebot/config.json:/data/config.json:ro \
          -e AUTH_URL="http://localhost:3002" \
          -e CONFIG_PATH="/data/config.json" \
          ghcr.io/sourcebot-dev/sourcebot:latest
      ''}";
      
      ExecStop = "${pkgs.docker}/bin/docker stop sourcebot";
      ExecStopPost = "${pkgs.docker}/bin/docker rm sourcebot";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Create management scripts
  home.file.".local/bin/sourcebot-start".source = pkgs.writeShellScript "sourcebot-start" ''
    #!${pkgs.bash}/bin/bash
    echo "Starting Sourcebot..."
    systemctl --user start sourcebot
    echo "Sourcebot started. Access at http://localhost:3002"
  '';
  home.file.".local/bin/sourcebot-start".executable = true;

  home.file.".local/bin/sourcebot-stop".source = pkgs.writeShellScript "sourcebot-stop" ''
    #!${pkgs.bash}/bin/bash
    echo "Stopping Sourcebot..."
    systemctl --user stop sourcebot
    echo "Sourcebot stopped."
  '';
  home.file.".local/bin/sourcebot-stop".executable = true;

  home.file.".local/bin/sourcebot-status".source = pkgs.writeShellScript "sourcebot-status" ''
    #!${pkgs.bash}/bin/bash
    systemctl --user status sourcebot --no-pager -l
  '';
  home.file.".local/bin/sourcebot-status".executable = true;

  home.file.".local/bin/sourcebot-logs".source = pkgs.writeShellScript "sourcebot-logs" ''
    #!${pkgs.bash}/bin/bash
    echo "Sourcebot systemd logs:"
    journalctl --user -u sourcebot.service -f --no-pager
  '';
  home.file.".local/bin/sourcebot-logs".executable = true;
}