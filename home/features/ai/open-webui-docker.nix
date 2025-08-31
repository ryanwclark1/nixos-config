{
  config,
  pkgs,
  ...
}:

{
  # Open WebUI Docker service managed by Home Manager
  systemd.user.services.open-webui-docker = {
    Unit = {
      Description = "Open WebUI Docker Container";
      After = [ "docker.service" "network-online.target" ];
      Wants = [ "docker.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 300;
      
      # Environment variables
      Environment = [
        "COMPOSE_PROJECT_NAME=openwebui"
        "DOCKER_BUILDKIT=1"
      ];
      
      # Start command - use docker compose without the deprecated version  
      ExecStart = pkgs.writeShellScript "start-open-webui" ''
        PATH="${pkgs.coreutils}/bin:${pkgs.docker}/bin:${pkgs.docker-compose}/bin:$PATH"
        set -euo pipefail
        
        # Create docker-compose.yml in runtime directory
        cat > $HOME/.config/open-webui/docker-compose.yml << 'EOF'
        services:
          open-webui:
            image: ghcr.io/open-webui/open-webui:v0.6.18
            container_name: open-webui
            volumes:
              - open-webui:/app/backend/data
              - $HOME/Documents:/app/backend/data/docs
              - /tmp:/tmp
            ports:
              - "8180:8080"
            environment:
              # Core Configuration
              - OLLAMA_BASE_URL=http://host.docker.internal:11434
              - WEBUI_SECRET_KEY=your-secret-key-change-in-production
              
              # Privacy & Analytics
              - ANONYMIZED_TELEMETRY=False
              - DO_NOT_TRACK=True
              - SCARF_NO_ANALYTICS=True
              
              # Performance Optimizations for AMD RX 7800 XT + 62GB RAM
              - OLLAMA_MAX_LOADED_MODELS=3
              - OLLAMA_NUM_PARALLEL=4
              - OLLAMA_FLASH_ATTENTION=1
              
              # File Upload & Processing  
              - ENABLE_RAG_WEB_SEARCH=True
              - ENABLE_RAG_LOCAL_WEB_FETCH=True
              - RAG_WEB_SEARCH_ENGINE=searxng
              - ENABLE_IMAGE_GENERATION=False
              
              # Document Processing
              - MAX_FILE_SIZE=100MB
              - CHUNK_SIZE=1000
              - CHUNK_OVERLAP=200
              
              # Security Headers
              - ENABLE_SECURITY_HEADERS=True
              - CORS_ALLOW_ORIGIN=*
              
              # Session & Auth Settings
              - WEBUI_AUTH=False
              - SESSION_COOKIE_SECURE=False
              - SESSION_COOKIE_SAMESITE=Lax
              
              # Logging
              - LOG_LEVEL=INFO
              - WEBUI_LOG_LEVEL=INFO
              
              # Model Management - Your optimized models
              - ENABLE_MODEL_FILTER=True
              - MODEL_FILTER_LIST=qwen3:30b-thinking;deepseek-r1:70b;qwen3-coder:30b-a3b-q8_0;magistral:24b-small-2506-q8_0
              
              # API Features
              - ENABLE_OPENAI_API=True
              
              # Advanced Features
              - ENABLE_ADMIN_EXPORT=True
              - ENABLE_ADMIN_CHAT_ACCESS=True
              - TASK_MODEL=qwen3:30b-thinking
              
            extra_hosts:
              - "host.docker.internal:host-gateway"
            
            # Resource limits optimized for your hardware
            deploy:
              resources:
                limits:
                  memory: 8G
                  cpus: '4.0'
                reservations:
                  memory: 2G
                  cpus: '1.0'
            
            restart: always
            
            healthcheck:
              test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
              interval: 30s
              timeout: 10s
              retries: 3
              start_period: 60s

        volumes:
          open-webui:
            driver: local
        EOF
        
        # Start the service
        cd $HOME/.config/open-webui
        ${pkgs.docker-compose}/bin/docker-compose up -d
      '';
      
      # Stop command
      ExecStop = pkgs.writeShellScript "stop-open-webui" ''
        PATH="${pkgs.coreutils}/bin:${pkgs.docker}/bin:${pkgs.docker-compose}/bin:$PATH"
        set -euo pipefail
        cd $HOME/.config/open-webui
        ${pkgs.docker-compose}/bin/docker-compose down
      '';
      
      # Reload command
      ExecReload = pkgs.writeShellScript "reload-open-webui" ''
        PATH="${pkgs.coreutils}/bin:${pkgs.docker}/bin:${pkgs.docker-compose}/bin:$PATH"
        set -euo pipefail
        cd $HOME/.config/open-webui
        ${pkgs.docker-compose}/bin/docker-compose down
        ${pkgs.docker-compose}/bin/docker-compose up -d
      '';
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Create config directory
  home.file.".config/open-webui/.keep".text = "";

  # Add docker-compose to user packages for manual management
  home.packages = with pkgs; [
    docker-compose
  ];
}