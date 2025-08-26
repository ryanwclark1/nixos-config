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
      nixos-config = {
        type = "git";
        url = "file:///repos/nixos-config";
      };

      # All repositories in Code directory using glob pattern
      code-repositories = {
        type = "git";
        url = "file:///repos/Code/*";
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

    # Performance and behavior settings (only valid schema properties)
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

    # Note: Search contexts are Enterprise-only features and have been removed
    # All repositories configured in connections will be searchable without contexts
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
          - "${config.home.homeDirectory}/Code:/repos/Code:ro"
          - "${config.home.homeDirectory}/nixos-config:/repos/nixos-config:ro"
        environment:
          # Core Configuration
          - CONFIG_PATH=/data/config.json
          - DATA_DIR=/data
          - DATA_CACHE_DIR=/data/.sourcebot

          # Authentication & Security
          - AUTH_URL=http://localhost:3002
          - AUTH_CREDENTIALS_LOGIN_ENABLED=true   # Enable standard username/password auth
          - AUTH_EMAIL_CODE_LOGIN_ENABLED=false   # Keep email login disabled for simplicity
          - AUTH_SECRET  # Loaded from SOPS via environment file

          # Database Connections - credentials loaded from SOPS via environment file
          - DATABASE_URL  # Will be constructed from SOPS secrets
          - REDIS_URL=redis://redis:6379

          # GitHub Integration - Token loaded from SOPS via environment file
          - GITHUB_PERSONAL_ACCESS_TOKEN

          # Logging & Telemetry
          - SOURCEBOT_LOG_LEVEL=info
          - SOURCEBOT_TELEMETRY_DISABLED=true

          # Security & Encryption
          - SOURCEBOT_ENCRYPTION_KEY=local-dev-key-change-in-production-32chars

          # Performance Tuning
          - NODE_ENV=production
          - NODE_OPTIONS=--max-old-space-size=4096

          # Network Configuration
          - PORT=3000
          - HOST=0.0.0.0

          # Development & Debugging
          - DEBUG=sourcebot:*
          - SOURCEBOT_DEBUG=false

          # Worker Configuration
          - WORKER_CONCURRENCY=4
          - INDEXING_BATCH_SIZE=100


          # File Processing & Indexing
          - INDEXING_EXCLUDE_PATTERNS=node_modules/**,.git/**,**/*.min.js,**/*.min.css,**/*.map,**/dist/**,**/build/**,**/.next/**,**/.venv/**,**/__pycache__/**,**/.pytest_cache/**,**/.ruff_cache/**,**/target/**,**/vendor/**
          - MAX_FILE_SIZE_BYTES=2097152  # 2 MB
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
          - POSTGRES_DB  # Loaded from SOPS via environment file
          - POSTGRES_USER  # Loaded from SOPS via environment file
          - POSTGRES_PASSWORD  # Loaded from SOPS via environment file
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

          # Create environment file for Sourcebot (disable shell coloring to avoid ANSI codes)
          export NO_COLOR=1
          export TERM=dumb

          # Read secrets from SOPS (hierarchical structure)
          GITHUB_TOKEN=$(cat ${config.sops.secrets.github-pat.path} 2>/dev/null | tr -d '[:cntrl:]' || echo "fake-token")
          AUTH_SECRET=$(cat ${config.sops.secrets."sourcebot/auth-secret".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "fallback-secret")
          DB_USER=$(cat ${config.sops.secrets."sourcebot/database/user".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")
          DB_PASSWORD=$(cat ${config.sops.secrets."sourcebot/database/password".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")
          DB_NAME=$(cat ${config.sops.secrets."sourcebot/database/name".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")

          # Create environment file with all secrets
          cat > ${config.home.homeDirectory}/.config/sourcebot/.env <<EOF
          GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN
          AUTH_SECRET=$AUTH_SECRET
          DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME
          POSTGRES_DB=$DB_NAME
          POSTGRES_USER=$DB_USER
          POSTGRES_PASSWORD=$DB_PASSWORD
          EOF
          chmod 600 ${config.home.homeDirectory}/.config/sourcebot/.env

          echo "Starting Sourcebot with PostgreSQL and Redis..."
        ''}"
      ];

      ExecStart = "${pkgs.writeShellScript "sourcebot-start" ''
        set -e

        COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
        ENV_FILE="${config.home.homeDirectory}/.config/sourcebot/.env"

        echo "[INFO] Starting Sourcebot services..."

        # Verify environment file exists
        if [ ! -f "$ENV_FILE" ]; then
          echo "[ERROR] Environment file not found at $ENV_FILE"
          echo "[ERROR] This should have been created in ExecStartPre"
          exit 1
        fi
        echo "[INFO] Environment file found: $ENV_FILE"

        # Check for port conflicts before starting
        echo "[INFO] Checking for port conflicts..."
        PORTS=(3002 5433 6380)
        for port in "''${PORTS[@]}"; do
          if ${pkgs.nettools}/bin/netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo "[WARNING] Port $port is already in use"
            if [ "$port" = "3002" ]; then
              echo "[INFO] Checking if existing Sourcebot container is running..."
              if ${pkgs.docker}/bin/docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "sourcebot.*Up"; then
                echo "[ERROR] Sourcebot container already running. Stop it first with: docker stop sourcebot"
                exit 1
              fi
            fi
          else
            echo "[INFO] Port $port is available"
          fi
        done

        # Check for existing containers with same names
        echo "[INFO] Checking for container name conflicts..."
        CONTAINERS=(sourcebot sourcebot-postgres sourcebot-redis)
        for container in "''${CONTAINERS[@]}"; do
          if ${pkgs.docker}/bin/docker ps -a --format "{{.Names}}" | grep -q "^$container$"; then
            echo "[WARNING] Container $container already exists"
            echo "[INFO] Removing existing container: $container"
            ${pkgs.docker}/bin/docker rm -f "$container" || true
          fi
        done

        # Start all services using environment file
        echo "[INFO] Starting Docker Compose services..."
        ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

        # Verify all containers started and are healthy
        echo "[INFO] Waiting for services to be ready..."
        sleep 10

        # Check container status
        RUNNING_CONTAINERS=$(${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running")
        ALL_SERVICES="sourcebot postgres redis"

        for service in $ALL_SERVICES; do
          if echo "$RUNNING_CONTAINERS" | grep -q "$service"; then
            echo "[INFO] $service: ✅ Running"
          else
            echo "[WARNING] $service: ❌ Not running"
          fi
        done

        # Check network connectivity
        SOURCEBOT_NETWORK=$(${pkgs.docker}/bin/docker inspect sourcebot --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}}{{end}}' 2>/dev/null || echo "none")
        POSTGRES_NETWORK=$(${pkgs.docker}/bin/docker inspect sourcebot-postgres --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}}{{end}}' 2>/dev/null || echo "none")

        if [ "$SOURCEBOT_NETWORK" = "$POSTGRES_NETWORK" ] && [ "$SOURCEBOT_NETWORK" != "none" ]; then
          echo "[INFO] Network connectivity: ✅ All containers on network: $SOURCEBOT_NETWORK"
        else
          echo "[WARNING] Network mismatch: sourcebot on $SOURCEBOT_NETWORK, postgres on $POSTGRES_NETWORK"
        fi

        echo "[SUCCESS] Sourcebot services started!"
        echo "Web interface: http://localhost:3002"
        echo "PostgreSQL: localhost:5433 (user: sourcebot, db: sourcebot)"
        echo "Redis: localhost:6380"
      ''}";

      ExecStop = "${pkgs.writeShellScript "sourcebot-stop" ''
        COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"

        echo "[INFO] Stopping Sourcebot services..."

        # Use Docker Compose to stop services gracefully
        if [ -f "$COMPOSE_FILE" ]; then
          ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" down --timeout 30
        else
          echo "[WARNING] Compose file not found, stopping containers manually..."
          ${pkgs.docker}/bin/docker stop sourcebot sourcebot-postgres sourcebot-redis 2>/dev/null || true
          ${pkgs.docker}/bin/docker rm sourcebot sourcebot-postgres sourcebot-redis 2>/dev/null || true
        fi

        # Clean up environment file
        rm -f ${config.home.homeDirectory}/.config/sourcebot/.env
        echo "[SUCCESS] Sourcebot services stopped and cleaned up."
      ''}";

      ExecReload = "${pkgs.writeShellScript "sourcebot-reload" ''
        COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
        ENV_FILE="${config.home.homeDirectory}/.config/sourcebot/.env"

        echo "[INFO] Reloading Sourcebot configuration..."

        # Recreate environment file with fresh SOPS secrets (disable shell coloring)
        export NO_COLOR=1
        export TERM=dumb

        # Read secrets from SOPS (hierarchical structure)
        GITHUB_TOKEN=$(cat ${config.sops.secrets.github-pat.path} 2>/dev/null | tr -d '[:cntrl:]' || echo "fake-token")
        AUTH_SECRET=$(cat ${config.sops.secrets."sourcebot/auth-secret".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "fallback-secret")
        DB_USER=$(cat ${config.sops.secrets."sourcebot/database/user".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")
        DB_PASSWORD=$(cat ${config.sops.secrets."sourcebot/database/password".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")
        DB_NAME=$(cat ${config.sops.secrets."sourcebot/database/name".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")

        # Create environment file with all secrets
        cat > "$ENV_FILE" <<EOF
        GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN
        AUTH_SECRET=$AUTH_SECRET
        DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME
        POSTGRES_DB=$DB_NAME
        POSTGRES_USER=$DB_USER
        POSTGRES_PASSWORD=$DB_PASSWORD
        EOF
        chmod 600 "$ENV_FILE"
        echo "[INFO] Environment file updated"

        # Restart only the main sourcebot container
        echo "[INFO] Restarting Sourcebot container..."
        ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" restart sourcebot
        echo "[SUCCESS] Sourcebot reloaded."
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

  # Manual Docker Compose management (bypassing systemd)
  home.file.".local/bin/sourcebot-docker-start".source = pkgs.writeShellScript "sourcebot-docker-start" ''
    #!/usr/bin/env bash
    set -e

    COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"
    ENV_FILE="${config.home.homeDirectory}/.config/sourcebot/.env"

    echo "Starting Sourcebot manually via Docker Compose..."

    # Ensure directories exist
    mkdir -p ${config.home.homeDirectory}/Code
    mkdir -p ${config.home.homeDirectory}/.config/sourcebot

    # Create environment file with SOPS secrets (disable shell coloring)
    export NO_COLOR=1
    export TERM=dumb

    # Read secrets from SOPS (hierarchical structure)
    GITHUB_TOKEN=$(cat ${config.sops.secrets.github-pat.path} 2>/dev/null | tr -d '[:cntrl:]' || echo "fake-token")
    AUTH_SECRET=$(cat ${config.sops.secrets."sourcebot/auth-secret".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "fallback-secret")
    DB_USER=$(cat ${config.sops.secrets."sourcebot/database/user".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")
    DB_PASSWORD=$(cat ${config.sops.secrets."sourcebot/database/password".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")
    DB_NAME=$(cat ${config.sops.secrets."sourcebot/database/name".path} 2>/dev/null | tr -d '[:cntrl:]' || echo "sourcebot")

    # Create environment file with all secrets
    cat > "$ENV_FILE" <<EOF
    GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN
    AUTH_SECRET=$AUTH_SECRET
    DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME
    POSTGRES_DB=$DB_NAME
    POSTGRES_USER=$DB_USER
    POSTGRES_PASSWORD=$DB_PASSWORD
    EOF
    chmod 600 "$ENV_FILE"
    echo "Created environment file with secrets from SOPS"

    # Start services
    ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

    echo "Sourcebot started manually!"
    echo "Web interface: http://localhost:3002"
    echo "Use 'sourcebot-docker-stop' to stop"
  '';
  home.file.".local/bin/sourcebot-docker-start".executable = true;

  home.file.".local/bin/sourcebot-docker-stop".source = pkgs.writeShellScript "sourcebot-docker-stop" ''
    #!/usr/bin/env bash
    COMPOSE_FILE="${config.home.homeDirectory}/.config/sourcebot/docker-compose.yml"

    echo "Stopping Sourcebot Docker services..."
    ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" down

    # Clean up environment file
    rm -f ${config.home.homeDirectory}/.config/sourcebot/.env
    echo "Sourcebot stopped and cleaned up."
  '';
  home.file.".local/bin/sourcebot-docker-stop".executable = true;

  # Add required packages
  home.packages = with pkgs; [
    docker-compose  # For compatibility scripts, but systemd uses modern 'docker compose'
    curl
    nettools  # For netstat port checking
  ];
}
