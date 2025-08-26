{
  config,
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
  # Create Sourcebot configuration 
  home.file.".config/sourcebot/config.json".source = sourcebotConfig;

  # Create Sourcebot management scripts
  home.file.".local/bin/sourcebot-start".source = pkgs.writeShellScript "sourcebot-start" ''
    #!${pkgs.bash}/bin/bash
    set -e
    
    # Create data directory
    mkdir -p ${config.home.homeDirectory}/.local/share/sourcebot
    
    echo "Starting Sourcebot..."
    ${pkgs.docker}/bin/docker run \
      --rm \
      --name sourcebot \
      -p 127.0.0.1:3002:3000 \
      -v ${config.home.homeDirectory}/.local/share/sourcebot:/data \
      -v ${config.home.homeDirectory}/.config/sourcebot/config.json:/data/config.json:ro \
      -e AUTH_URL="http://localhost:3002" \
      -e CONFIG_PATH="/data/config.json" \
      ghcr.io/sourcebot-dev/sourcebot:latest &
      
    echo "Sourcebot started in background. Access at http://localhost:3002"
    echo "Use 'sourcebot-stop' to stop the service."
  '';
  home.file.".local/bin/sourcebot-start".executable = true;

  home.file.".local/bin/sourcebot-stop".source = pkgs.writeShellScript "sourcebot-stop" ''
    #!${pkgs.bash}/bin/bash
    echo "Stopping Sourcebot..."
    ${pkgs.docker}/bin/docker stop sourcebot 2>/dev/null || echo "Sourcebot was not running"
    echo "Sourcebot stopped."
  '';
  home.file.".local/bin/sourcebot-stop".executable = true;

  home.file.".local/bin/sourcebot-status".source = pkgs.writeShellScript "sourcebot-status" ''
    #!${pkgs.bash}/bin/bash
    echo "Checking Sourcebot status..."
    if ${pkgs.docker}/bin/docker ps --filter "name=sourcebot" --format "{{.Names}}" | grep -q "sourcebot"; then
      echo "✅ Sourcebot is running"
      ${pkgs.docker}/bin/docker ps --filter "name=sourcebot"
    else
      echo "❌ Sourcebot is not running"
    fi
  '';
  home.file.".local/bin/sourcebot-status".executable = true;

  home.file.".local/bin/sourcebot-logs".source = pkgs.writeShellScript "sourcebot-logs" ''
    #!${pkgs.bash}/bin/bash
    echo "Sourcebot Docker logs:"
    ${pkgs.docker}/bin/docker logs -f sourcebot
  '';
  home.file.".local/bin/sourcebot-logs".executable = true;
}