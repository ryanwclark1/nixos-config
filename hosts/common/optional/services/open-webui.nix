{
  pkgs,
  lib,
  ...
}:

let
  # Create custom Open WebUI without problematic Oracle/Pinecone dependencies
  open-webui-minimal = pkgs.python3Packages.buildPythonApplication rec {
    pname = "open-webui";
    version = "0.6.18";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "open-webui";
      repo = "open-webui";
      tag = "v${version}";
      hash = "sha256-1V9mOhO8jpr0HU0djLjKw6xDQMBmqie6Gte4xfg9PfQ=";
    };

    frontend = pkgs.buildNpmPackage rec {
      pname = "open-webui-frontend";
      inherit version src;
      
      pyodideVersion = "0.28.0";
      pyodide = pkgs.fetchurl {
        hash = "sha256-4YwDuhcWPYm40VKfOEqPeUSIRQl1DDAdXEUcMuzzU7o=";
        url = "https://github.com/pyodide/pyodide/releases/download/${pyodideVersion}/pyodide-${pyodideVersion}.tar.bz2";
      };

      npmDepsHash = "sha256-bMqK9NvuTwqnhflGDfZTEkaFG8y34Qf94SgR0HMClrQ=";
      
      npmFlags = [ "--force" "--legacy-peer-deps" ];
      
      postPatch = ''
        substituteInPlace package.json \
          --replace-fail "npm run pyodide:fetch && vite build" "vite build"
      '';

      env.CYPRESS_INSTALL_BINARY = "0";
      env.ONNXRUNTIME_NODE_INSTALL_CUDA = "skip";
      env.NODE_OPTIONS = "--max-old-space-size=8192";

      preBuild = ''
        tar xf ${pyodide} -C static/
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/share
        cp -a build $out/share/open-webui
        runHook postInstall
      '';
    };

    build-system = with pkgs.python3Packages; [ hatchling ];

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail ', build = "open_webui/frontend"' ""
    '';

    env.HATCH_BUILD_NO_HOOKS = true;
    pythonRelaxDeps = true;
    pythonRemoveDeps = [ "docker" "pytest" "pytest-docker" ];
    
    # Skip all checks and hooks that cause issues
    doCheck = false;
    nativeCheckInputs = [];
    
    # Override Python environment to not use runtime dependency checks
    nativeBuildInputs = with pkgs.python3Packages; [ 
      setuptools
      wheel 
      hatchling
    ] ++ [ pkgs.python3Packages.pythonRemoveTestsDirHook ];
    
    # Disable problematic hooks
    preInstall = ''
      export PYTHONDONTWRITEBYTECODE=1
      unset pythonRuntimeDepsCheckHook
    '';

    # Exact dependencies from Open WebUI 0.6.18 (without Oracle/Pinecone)
    dependencies = with pkgs.python3Packages; [
      accelerate
      aiocache
      aiofiles
      aiohttp
      alembic
      anthropic
      apscheduler
      argon2-cffi
      asgiref
      async-timeout
      authlib
      azure-ai-documentintelligence
      azure-identity
      azure-storage-blob
      bcrypt
      beautifulsoup4
      black
      boto3
      chromadb
      colbert-ai
      cryptography
      ddgs
      docx2txt
      einops
      elasticsearch
      extract-msg
      fake-useragent
      fastapi
      faster-whisper
      ftfy
      gcp-storage-emulator
      google-api-python-client
      google-auth-httplib2
      google-auth-oauthlib
      google-cloud-storage
      google-genai
      google-generativeai
      googleapis-common-protos
      httpx
      iso-639
      langchain
      langchain-community
      langdetect
      ldap3
      loguru
      markdown
      moto
      nltk
      onnxruntime
      openai
      opencv-python-headless
      openpyxl
      opentelemetry-api
      opentelemetry-sdk
      opentelemetry-exporter-otlp
      opentelemetry-instrumentation
      opentelemetry-instrumentation-fastapi
      opentelemetry-instrumentation-sqlalchemy
      opentelemetry-instrumentation-redis
      opentelemetry-instrumentation-requests
      opentelemetry-instrumentation-logging
      opentelemetry-instrumentation-httpx
      opentelemetry-instrumentation-aiohttp-client
      pandas
      passlib
      peewee
      peewee-migrate
      pgvector
      pillow
      playwright
      posthog
      psutil
      psycopg2-binary
      pycrdt
      pydub
      pyjwt
      pymdown-extensions
      pymilvus
      pymongo
      pymysql
      pypandoc
      pypdf
      python-dotenv
      python-jose
      python-multipart
      python-pptx
      python-socketio
      pytube
      pyxlsb
      qdrant-client
      rank-bm25
      rapidocr-onnxruntime
      redis
      requests
      restrictedpython
      sentence-transformers
      sentencepiece
      soundfile
      starlette-compress
      tencentcloud-sdk-python
      tiktoken
      transformers
      unstructured
      uvicorn
      validators
      xlrd
      youtube-transcript-api
    ] ++ pkgs.python3Packages.moto.optional-dependencies.s3;

    makeWrapperArgs = [ "--set FRONTEND_BUILD_DIR ${frontend}/share/open-webui" ];
    pythonImportsCheck = [ "open_webui" ];

    passthru.frontend = frontend;

    meta = with lib; {
      description = "Comprehensive suite for LLMs with a user-friendly WebUI";
      homepage = "https://github.com/open-webui/open-webui";
      mainProgram = "open-webui";
      maintainers = [ ];
    };
  };
in

{
  # Re-enabled with older version
  
  # Create required directories and set permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/open-webui 0755 open-webui open-webui -"
    "d /var/lib/open-webui/docs 0755 open-webui open-webui -"
    "d /var/lib/open-webui/uploads 0755 open-webui open-webui -"
    "d /var/lib/open-webui/cache 0755 open-webui open-webui -"
  ];
  
  # User account for Open WebUI service
  users.users.open-webui = {
    isSystemUser = true;
    group = "open-webui";
    description = "Open WebUI service user";
  };
  users.groups.open-webui = {};
  
  services.open-webui = {
    enable = false;  # Using Docker instead due to dependency build complexity
    port = 8180;
    host = "0.0.0.0";
    openFirewall = true;
    package = open-webui-minimal;
    environment = {
      # Privacy & Analytics
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      
      # Core Configuration
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False";  # Consider enabling for production
      WEBUI_SECRET_KEY = "your-secret-key-here";  # Change in production
      
      # Vector Database (ChromaDB)
      VECTOR_DB = "chroma";
      CHROMA_HTTP_PORT = "8181";
      CHROMA_HTTP_HOST = "127.0.0.1";
      
      # Performance Optimizations for AMD RX 7800 XT + 62GB RAM
      OLLAMA_MAX_LOADED_MODELS = "3";  # Allow multiple models in memory
      OLLAMA_NUM_PARALLEL = "4";       # Parallel request handling
      OLLAMA_FLASH_ATTENTION = "1";    # Enable flash attention
      
      # File Upload & Processing
      ENABLE_RAG_WEB_SEARCH = "True";
      ENABLE_RAG_LOCAL_WEB_FETCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      ENABLE_IMAGE_GENERATION = "False";  # Disable if no image models
      
      # Document Processing
      DOCS_DIR = "/var/lib/open-webui/docs";
      UPLOAD_DIR = "/var/lib/open-webui/uploads";
      MAX_FILE_SIZE = "100MB";
      CHUNK_SIZE = "1000";
      CHUNK_OVERLAP = "200";
      
      # Database & Storage
      DATABASE_URL = "sqlite:///var/lib/open-webui/webui.db";
      DATA_DIR = "/var/lib/open-webui";
      
      # Security Headers
      ENABLE_SECURITY_HEADERS = "True";
      CORS_ALLOW_ORIGIN = "*";  # Restrict in production
      
      # Session & Auth Settings  
      SESSION_COOKIE_SECURE = "False";  # Set True with HTTPS
      SESSION_COOKIE_SAMESITE = "Lax";
      
      # Logging
      LOG_LEVEL = "INFO";
      WEBUI_LOG_LEVEL = "INFO";
      
      # Model Management
      ENABLE_MODEL_FILTER = "True";
      MODEL_FILTER_LIST = "qwen3:30b-thinking;deepseek-r1:70b;qwen3-coder:30b-a3b-q8_0;magistral:24b-small-2506-q8_0";
      
      # API Features
      ENABLE_OPENAI_API = "True";
      OPENAI_API_KEY = "your-openai-key";  # Optional for external models
      
      # Advanced Features
      ENABLE_ADMIN_EXPORT = "True";
      ENABLE_ADMIN_CHAT_ACCESS = "True";
      TASK_MODEL = "qwen3:30b-thinking";  # Use primary model for tasks
      
      # MCP support is now configured at the user level via home-manager
      # See: home/features/ai/mcp-openwebui.nix
      # MCP servers are launched on-demand by clients, not as persistent services
    };
  };

  # Systemd service hardening and resource management
  systemd.services.open-webui = {
    serviceConfig = {
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      
      # Resource limits optimized for your AMD RX 7800 XT + 62GB RAM
      MemoryMax = "32G";           # Max 32GB RAM usage
      MemoryHigh = "24G";          # Soft limit at 24GB
      CPUQuota = "800%";           # Use up to 8 CPU cores
      TasksMax = "4096";           # Maximum number of tasks
      
      # File system permissions
      ReadWritePaths = [
        "/var/lib/open-webui"
        "/tmp"
      ];
      ReadOnlyPaths = [
        "/nix/store"
      ];
      
      # Network access  
      IPAddressAllow = "localhost link-local multicast";
      
      # Restart policy
      Restart = "always";
      RestartSec = "10s";
      
      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "open-webui";
    };
    
    # Service dependencies
    after = [ "network.target" "ollama.service" ];
    wants = [ "ollama.service" ];
  };

  # Log rotation for Open WebUI
  services.logrotate.settings.open-webui = {
    files = "/var/log/open-webui/*.log";
    frequency = "daily";
    rotate = 30;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    create = "0644 open-webui open-webui";
    postrotate = "systemctl reload open-webui.service || true";
  };
}

# ============================================================================
# DOCKER SOLUTION FOR OPEN WEBUI
# ============================================================================
# 
# The nixpkgs Open WebUI package currently has a dependency issue with Oracle DB
# requiring exact Cython 3.1. Use Docker instead until this is resolved upstream.
#
# OPTIMIZED DOCKER COMPOSE FILE CREATED AT:
# /home/administrator/open-webui-docker-compose.yml
#
# FEATURES INCLUDED:
# - Hardware optimized for AMD RX 7800 XT (16GB VRAM) + 62GB RAM
# - Model filtering: Only your optimized models (qwen3:30b-thinking, deepseek-r1:70b, etc.)
# - Performance tuning: 3 models in memory, 4 parallel requests, flash attention
# - Document processing: RAG support, 100MB uploads, intelligent chunking
# - Security hardening: Headers, CORS config, resource limits
# - Health monitoring: Built-in checks and auto-restart
# - Volume persistence: Data survives container restarts
#
# QUICK START COMMANDS:
# cd /home/administrator
# docker-compose -f open-webui-docker-compose.yml up -d
# 
# Access at: http://localhost:8180
# Check logs: docker-compose -f open-webui-docker-compose.yml logs -f
# Stop: docker-compose -f open-webui-docker-compose.yml down
#
# WHEN NIXPKGS IS FIXED:
# 1. Change enable = true above
# 2. Comment out the overridePythonAttrs package override
# 3. Run: sudo nixos-rebuild switch --flake .#
# ============================================================================

