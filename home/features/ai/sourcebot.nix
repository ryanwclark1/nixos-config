{
  config,
  pkgs,
  ...
}:

{
  # Sourcebot - Self-hosted code understanding tool
  # Documentation: https://docs.sourcebot.dev/

  # Create Sourcebot configuration directory and config file
  home.file.".config/sourcebot/config.json".text = builtins.toJSON {
    "$schema" = "https://raw.githubusercontent.com/sourcebot-dev/sourcebot/main/schemas/v3/index.json";
    
    connections = {
      # GitHub connection using environment variable (populated from SOPS at runtime)
      github = {
        type = "github";
        token = {
          env = "GITHUB_PERSONAL_ACCESS_TOKEN";  # Environment variable
        };
        repos = [
          "sourcebot-dev/sourcebot"  # Example repo for testing
        ];
        users = [
          "ryanwclark"
          "ryanwclark1"
        ];
        orgs = [
          "AccentCommunications"
        ];
      };
      
      # Local repository connections
      code-repos = {
        type = "git";
        url = "file:///workspace/Code/*";  # All repos in ~/Code
      };
      
      nixos-config = {
        type = "git";
        url = "file:///workspace/nixos-config";  # NixOS configuration
      };
    };
    
    # Language models aligned with system Ollama configuration
    models = [
      {
        provider = "openai-compatible";
        model = "deepseek-r1:8b";
        displayName = "DeepSeek R1 8B (Ollama)";
        baseUrl = "http://host.docker.internal:11434/v1";
      }
      {
        provider = "openai-compatible";
        model = "qwen3-coder:30b";
        displayName = "Qwen3 Coder 30B (Ollama)";
        baseUrl = "http://host.docker.internal:11434/v1";
      }
      {
        provider = "openai-compatible";
        model = "gpt-oss:latest";
        displayName = "GPT OSS (Ollama)";
        baseUrl = "http://host.docker.internal:11434/v1";
      }
    ];
    
    # Performance and behavior settings
    settings = {
      maxFileSize = 2097152;  # 2 MB
      maxTrigramCount = 20000;
      reindexIntervalMs = 3600000;  # 1 hour
      resyncConnectionIntervalMs = 86400000;  # 24 hours
      resyncConnectionPollingIntervalMs = 1000;
      reindexRepoPollingIntervalMs = 1000;
      maxConnectionSyncJobConcurrency = 8;
      maxRepoIndexingJobConcurrency = 8;
      maxRepoGarbageCollectionJobConcurrency = 8;
      repoGarbageCollectionGracePeriodMs = 10000;
      repoIndexTimeoutMs = 7200000;  # 2 hours
    };
    
    # Search contexts for organizing repositories
    contexts = {
      personal = {
        name = "Personal Projects";
        repos = [
          "ryanwclark/*"
          "ryanwclark1/*"
        ];
      };
      work = {
        name = "Work Projects";
        repos = [
          "AccentCommunications/*"
        ];
      };
      local = {
        name = "Local Development";
        repos = [
          "code-repos"
          "nixos-config"
        ];
      };
    };
  };

  # Create Docker Compose configuration for Sourcebot with PostgreSQL and Redis
  home.file.".config/sourcebot/docker-compose.yml".text = ''
    services:
      sourcebot:
        image: ghcr.io/sourcebot-dev/sourcebot:latest
        container_name: sourcebot
        restart: unless-stopped
        ports:
          - "127.0.0.1:3002:3000"
        volumes:
          - sourcebot-data:/data
          - "${config.home.homeDirectory}/.config/sourcebot/config.json:/data/config.json:ro"
          - "${config.home.homeDirectory}/Code:/workspace/Code:ro"
          - "${config.home.homeDirectory}/nixos-config:/workspace/nixos-config:ro"
        environment:
          - CONFIG_PATH=/data/config.json
          - AUTH_URL=http://localhost:3002
          - DATABASE_URL=postgresql://sourcebot:sourcebot@postgres:5432/sourcebot
          - REDIS_URL=redis://redis:6379
          - SOURCEBOT_LOG_LEVEL=info
          - SOURCEBOT_TELEMETRY_DISABLED=true
          - GITHUB_PERSONAL_ACCESS_TOKEN
          # No authentication for local development
          - AUTH_CREDENTIALS_LOGIN_ENABLED=false
          - AUTH_EMAIL_CODE_LOGIN_ENABLED=false
        depends_on:
          postgres:
            condition: service_healthy
          redis:
            condition: service_healthy
        networks:
          - sourcebot-network
        healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
          interval: 30s
          timeout: 10s
          retries: 3
          start_period: 60s

      postgres:
        image: postgres:16-alpine
        container_name: sourcebot-postgres
        restart: unless-stopped
        ports:
          - "127.0.0.1:5433:5432"  # Use 5433 to avoid conflicts
        environment:
          - POSTGRES_DB=sourcebot
          - POSTGRES_USER=sourcebot
          - POSTGRES_PASSWORD=sourcebot
          - PGDATA=/var/lib/postgresql/data/pgdata
        volumes:
          - postgres-data:/var/lib/postgresql/data
        networks:
          - sourcebot-network
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U sourcebot -d sourcebot"]
          interval: 30s
          timeout: 10s
          retries: 5
          start_period: 30s

      redis:
        image: redis:7-alpine
        container_name: sourcebot-redis
        restart: unless-stopped
        ports:
          - "127.0.0.1:6380:6379"  # Use 6380 to avoid conflicts
        volumes:
          - redis-data:/data
        networks:
          - sourcebot-network
        healthcheck:
          test: ["CMD", "redis-cli", "ping"]
          interval: 30s
          timeout: 10s
          retries: 5
          start_period: 30s
        command: redis-server --appendonly yes

    volumes:
      sourcebot-data:
        driver: local
      postgres-data:
        driver: local
      redis-data:
        driver: local

    networks:
      sourcebot-network:
        driver: bridge
  '';

  # Sourcebot systemd service
  systemd.user.services.sourcebot = {
    Unit = {
      Description = "Sourcebot Code Intelligence Platform";
      After = [ "network.target" ];
      Wants = [ "network.target" ];
    };
    
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "600";
      TimeoutStopSec = "120";
      
      Environment = [
        "GITHUB_PERSONAL_ACCESS_TOKEN_FILE=${config.sops.secrets.github-pat.path}"
      ];
      
      ExecStartPre = [
        "${pkgs.writeShellScript "sourcebot-prepare" ''
          # Ensure required directories exist
          mkdir -p ${config.home.homeDirectory}/Code
          mkdir -p ${config.home.homeDirectory}/.config/sourcebot
          
          # Create environment file for Sourcebot
          cat > ${config.home.homeDirectory}/.config/sourcebot/.env <<EOF
          GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.sops.secrets.github-pat.path})
          EOF
          chmod 600 ${config.home.homeDirectory}/.config/sourcebot/.env
          
          echo "Starting Sourcebot with PostgreSQL and Redis..."
        ''}"
      ];
      
      ExecStart = "${pkgs.writeShellScript "sourcebot-start" ''
        set -e
        
        COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
        
        # Start all services using environment file
        ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" --env-file "${config.home.homeDirectory}/.config/sourcebot/.env" up -d
        
        echo "Sourcebot services started!"
        echo "Web interface: http://localhost:3002"
        echo "PostgreSQL: localhost:5433 (user: sourcebot, db: sourcebot)"
        echo "Redis: localhost:6380"
      ''}";
      
      ExecStop = "${pkgs.writeShellScript "sourcebot-stop" ''
        COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
        
        echo "Stopping Sourcebot services..."
        ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" down
        
        # Clean up environment file
        rm -f ${config.home.homeDirectory}/.config/sourcebot/.env
        echo "Sourcebot services stopped."
      ''}";
      
      ExecReload = "${pkgs.writeShellScript "sourcebot-reload" ''
        COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
        
        # Recreate environment file
        cat > ${config.home.homeDirectory}/.config/sourcebot/.env <<EOF
        GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.sops.secrets.github-pat.path})
        EOF
        chmod 600 ${config.home.homeDirectory}/.config/sourcebot/.env
        
        echo "Reloading Sourcebot configuration..."
        ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" restart sourcebot
        echo "Sourcebot reloaded."
      ''}";
    };
    
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Convenient management scripts
  home.file.".local/bin/sourcebot-start".source = pkgs.writeShellScript "sourcebot-start" ''
    #!/usr/bin/env bash
    echo "Starting Sourcebot via systemd..."
    systemctl --user start sourcebot
    echo "Use 'sourcebot-status' to check status"
  '';
  home.file.".local/bin/sourcebot-start".executable = true;

  home.file.".local/bin/sourcebot-stop".source = pkgs.writeShellScript "sourcebot-stop" ''
    #!/usr/bin/env bash
    echo "Stopping Sourcebot via systemd..."
    systemctl --user stop sourcebot
  '';
  home.file.".local/bin/sourcebot-stop".executable = true;

  home.file.".local/bin/sourcebot-status".source = pkgs.writeShellScript "sourcebot-status" ''
    #!/usr/bin/env bash
    COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
    
    echo "Sourcebot Service Status:"
    echo "========================"
    systemctl --user status sourcebot --no-pager -l
    
    echo ""
    echo "Docker Container Status:"
    echo "========================"
    ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" ps
    
    echo ""
    echo "Service Health:"
    echo "==============="
    echo "Sourcebot: http://localhost:3002"
    echo -n "Status: "
    if ${pkgs.curl}/bin/curl -sf http://localhost:3002/health >/dev/null 2>&1; then
      echo "✅ Healthy"
    else
      echo "❌ Not responding"
    fi
    
    echo ""
    echo "Database Status:"
    echo "================"
    if ${pkgs.docker}/bin/docker exec sourcebot-postgres pg_isready -U sourcebot -d sourcebot >/dev/null 2>&1; then
      echo "PostgreSQL: ✅ Ready"
    else
      echo "PostgreSQL: ❌ Not ready"
    fi
    
    if ${pkgs.docker}/bin/docker exec sourcebot-redis redis-cli ping >/dev/null 2>&1; then
      echo "Redis: ✅ Ready"
    else
      echo "Redis: ❌ Not ready"
    fi
  '';
  home.file.".local/bin/sourcebot-status".executable = true;

  home.file.".local/bin/sourcebot-logs".source = pkgs.writeShellScript "sourcebot-logs" ''
    #!/usr/bin/env bash
    COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
    
    if [ -z "$1" ]; then
      echo "Usage: sourcebot-logs [service]"
      echo "Available services: sourcebot, postgres, redis"
      echo "Or no argument to view all logs"
      echo ""
      echo "Systemd logs:"
      journalctl --user -u sourcebot -f --no-pager
    else
      echo "Docker logs for $1:"
      ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" logs -f "$1"
    fi
  '';
  home.file.".local/bin/sourcebot-logs".executable = true;

  home.file.".local/bin/sourcebot-restart".source = pkgs.writeShellScript "sourcebot-restart" ''
    #!/usr/bin/env bash
    COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
    
    if [ -z "$1" ]; then
      echo "Restarting all Sourcebot services..."
      systemctl --user reload sourcebot
    else
      echo "Restarting $1..."
      ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" restart "$1"
    fi
    echo "Restart completed."
  '';
  home.file.".local/bin/sourcebot-restart".executable = true;

  home.file.".local/bin/sourcebot-update".source = pkgs.writeShellScript "sourcebot-update" ''
    #!/usr/bin/env bash
    COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
    
    echo "Updating Sourcebot images..."
    ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" pull
    
    echo "Restarting services with updated images..."
    ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" up -d --force-recreate
    
    echo "Update completed!"
  '';
  home.file.".local/bin/sourcebot-update".executable = true;

  home.file.".local/bin/sourcebot-backup".source = pkgs.writeShellScript "sourcebot-backup" ''
    #!/usr/bin/env bash
    set -e
    
    BACKUP_DIR="${config.home.homeDirectory}/.local/share/sourcebot-backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    echo "Creating Sourcebot backup..."
    echo "Backup location: $BACKUP_DIR/sourcebot_$DATE"
    
    # Backup PostgreSQL database
    echo "Backing up PostgreSQL database..."
    ${pkgs.docker}/bin/docker exec sourcebot-postgres pg_dump -U sourcebot sourcebot > "$BACKUP_DIR/sourcebot_db_$DATE.sql"
    
    # Backup configuration
    echo "Backing up configuration..."
    cp "${config.home.homeDirectory}/.config/sourcebot/config.json" "$BACKUP_DIR/config_$DATE.json"
    
    # Backup Docker volumes (data)
    echo "Backing up data volumes..."
    ${pkgs.docker}/bin/docker run --rm -v sourcebot_sourcebot-data:/data -v "$BACKUP_DIR:/backup" alpine tar czf "/backup/sourcebot_data_$DATE.tar.gz" -C /data .
    
    echo "Backup completed successfully!"
    echo "Files created:"
    echo "  - Database: sourcebot_db_$DATE.sql"
    echo "  - Config: config_$DATE.json"  
    echo "  - Data: sourcebot_data_$DATE.tar.gz"
  '';
  home.file.".local/bin/sourcebot-backup".executable = true;

  # Add required packages
  home.packages = with pkgs; [
    docker-compose  # For compatibility scripts, but systemd uses modern 'docker compose'
    curl
  ];
}