{
  pkgs,
  config,
  ...
}:

{
  # MCP Server configuration for Open WebUI
  # MCP servers are launched on-demand by clients, not as persistent services
  
  home.packages = with pkgs; [
    # Required for on-demand Docker-based MCP servers
    docker
    # Native MCP servers
    playwright-mcp
    # Required for Sourcebot MCP server
    nodejs
    jq
  ];

  # Create MCP configuration directory and files
  home.file.".config/open-webui/mcp-servers.json".text = builtins.toJSON {
    # Git MCP Server - Repository insights and operations  
    git = {
      command = "docker";
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-git"
        "-v" "${config.home.homeDirectory}:${config.home.homeDirectory}:rw"
        "-v" "${config.home.homeDirectory}/.gitconfig:/root/.gitconfig:ro"
        "mcp/git"
      ];
      description = "Provides git repository information and operations";
    };

    # Memory MCP Server - Persistent context across sessions
    memory = {
      command = "docker";
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-memory"
        "-v" "mcp-memory-data:/data"
        "mcp/memory"
      ];
      env = {
        DATABASE_URL = "sqlite:///data/memory.db";
      };
      description = "Maintains context and memory across sessions";
    };

    # Time MCP Server - Date/time operations
    time = {
      command = "docker";
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-time"
        "mcp/time"
        "--local-timezone=America/Chicago"
      ];
      env = {
        TZ = "America/Chicago";
      };
      description = "Provides date and time information and operations";
    };

    # Fetch MCP Server - Web content fetching
    fetch = {
      command = "docker"; 
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-fetch"
        "--network" "bridge"
        "mcp/fetch"
      ];
      description = "Fetches and analyzes web content";
    };

    # Context7 MCP Server - Up-to-date code documentation
    context7 = {
      command = "docker";
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-context7"
        "mcp/context7"
      ];
      env = {
        CONTEXT7_TOKEN = "$(cat ${config.sops.secrets.context7-token.path})";
        MCP_TRANSPORT = "stdio";
      };
      description = "Provides up-to-date code documentation for AI code editors";
    };

    # GitHub MCP Server - GitHub repository and workflow management
    github = {
      command = "docker";
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-github"
        "ghcr.io/github/github-mcp-server"
      ];
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "$(cat ${config.sops.secrets.github-pat.path})";
        GITHUB_TOOLSETS = "repos,issues,pull_requests,actions,code_security,discussions";
        MCP_TRANSPORT = "stdio";
      };
      description = "GitHub repository and workflow management via MCP";
    };

    # Playwright MCP Server - Browser automation and web scraping
    playwright = {
      command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
      args = [
        "--headless"
      ];
      description = "Browser automation and web scraping via Playwright";
    };

    # Serena MCP Server - AI-powered development assistant
    serena = {
      command = "docker";
      args = [
        "run"
        "-i" "--rm"
        "--name" "mcp-serena"
        "-v" "/home/administrator/Code:/workspace/Code:rw"
        "--network" "host"
        "ghcr.io/oraios/serena:latest"
        "serena" "start-mcp-server" "--transport" "stdio"
      ];
      env = {
        SERENA_DOCKER = "1";
      };
      description = "AI-powered development assistant with Code directory access";
    };

    # Sourcebot MCP Server - Code understanding and search
    sourcebot = {
      command = "npx";
      args = [
        "@sourcebot/mcp@latest"
      ];
      env = {
        NODE_ENV = "production";
        SOURCEBOT_HOST = "http://localhost:3002";
        SOURCEBOT_API_KEY = "$(cat ${config.sops.secrets."sourcebot/api-key".path})";
      };
      description = "Code understanding and search via Sourcebot";
    };

    # Sequential Thinking MCP Server - Step-by-step problem solving
    sequential-thinking = {
      command = "npx";
      args = [
        "@modelcontextprotocol/server-sequential-thinking@latest"
      ];
      env = {
        NODE_ENV = "production";
      };
      description = "Helps break down complex problems into sequential steps";
    };
  };

  # Simple management scripts for MCP troubleshooting
  home.file.".local/bin/mcp-test-docker".source = pkgs.writeShellScript "mcp-test-docker" ''
    #!/usr/bin/env bash
    echo "Testing Docker access for MCP servers..."
    if ${pkgs.docker}/bin/docker info >/dev/null 2>&1; then
      echo "[OK] Docker is accessible"
    else
      echo "[ERROR] Docker is not accessible. MCP servers that use Docker will fail."
      echo "Make sure Docker is running and your user has access."
    fi
  '';
  home.file.".local/bin/mcp-test-docker".executable = true;

  home.file.".local/bin/mcp-list-servers".source = pkgs.writeShellScript "mcp-list-servers" ''
    #!/usr/bin/env bash
    echo "Available MCP Servers:"
    echo "====================="
    echo "Git: Repository operations and insights"
    echo "Memory: Persistent context across sessions"  
    echo "Time: Date and time operations"
    echo "Fetch: Web content fetching and analysis"
    echo "Context7: Up-to-date code documentation"
    echo "GitHub: GitHub repository and workflow management"
    echo "Playwright: Browser automation and web scraping"
    echo "Serena: AI-powered development assistant"
    echo "Sourcebot: Code understanding and search"
    echo "Sequential Thinking: Step-by-step problem solving"
    echo ""
    echo "These servers are launched automatically when MCP clients need them."
    echo "Configuration: ~/.config/open-webui/mcp-servers.json"
  '';
  home.file.".local/bin/mcp-list-servers".executable = true;

  home.file.".local/bin/mcp-test-playwright".source = pkgs.writeShellScript "mcp-test-playwright" ''
    #!/usr/bin/env bash
    set -e
    
    echo "Testing Playwright MCP server..."
    echo "Browser path: ${pkgs.playwright-driver.browsers}"
    
    # Check if browsers are available
    if [ -d "${pkgs.playwright-driver.browsers}" ]; then
      echo "[OK] Playwright browsers directory found"
      
      # Check for Chromium specifically
      CHROMIUM_PATH="${pkgs.playwright-driver.browsers}/chromium-1181/chrome-linux/chrome"
      if [ -f "$CHROMIUM_PATH" ]; then
        echo "[OK] Chromium browser found"
        "$CHROMIUM_PATH" --version 2>/dev/null || echo "Version check failed"
      else
        echo "[WARN] Chromium not found at expected path, but may be auto-detected"
      fi
    else
      echo "[ERROR] Playwright browsers directory not found"
    fi
    
    echo ""
    echo "Testing MCP server initialization (using auto-detected browsers)..."
    echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}, "resources": {}}, "clientInfo": {"name": "test", "version": "1.0"}}}' | \
      ${pkgs.playwright-mcp}/bin/mcp-server-playwright --headless || echo "MCP server test failed"
    
    echo "[OK] Playwright MCP test completed"
  '';
  home.file.".local/bin/mcp-test-playwright".executable = true;

  home.file.".local/bin/mcp-test-sourcebot".source = pkgs.writeShellScript "mcp-test-sourcebot" ''
    #!/usr/bin/env bash
    echo "Testing Sourcebot MCP server dependencies..."
    
    # Test Sourcebot availability
    if ${pkgs.curl}/bin/curl -sf http://localhost:3002/health >/dev/null 2>&1; then
      echo "[OK] Sourcebot is running at http://localhost:3002"
    else
      echo "[ERROR] Sourcebot is not running. Start with 'sourcebot-start'"
      exit 1
    fi
    
    # Test Node.js
    if ${pkgs.nodejs}/bin/node --version >/dev/null 2>&1; then
      echo "[OK] Node.js is available: $(${pkgs.nodejs}/bin/node --version)"
    else
      echo "[ERROR] Node.js is not available"
    fi
    
    # Test SOPS API key availability
    echo "Checking for Sourcebot API key from SOPS..."
    if [ -f "${config.sops.secrets."sourcebot/api-key".path}" ]; then
      API_KEY=$(cat ${config.sops.secrets."sourcebot/api-key".path} 2>/dev/null)
      if [ -n "$API_KEY" ] && [ "$API_KEY" != "null" ]; then
        echo "[OK] Sourcebot API key found in SOPS secrets"
      else
        echo "[WARN] API key file exists but appears empty"
      fi
    else
      echo "[WARN] SOPS API key file not found at ${config.sops.secrets."sourcebot/api-key".path}"
    fi
    
    echo ""
    echo "Sourcebot MCP server should be ready to use."
  '';
  home.file.".local/bin/mcp-test-sourcebot".executable = true;
}