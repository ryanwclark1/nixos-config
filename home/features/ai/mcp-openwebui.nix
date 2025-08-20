{
  pkgs,
  config,
  ...
}:

{
  # MCP Server configuration for Open WebUI
  # This configures MCP servers to work with Open WebUI via mcpo proxy
  
  home.packages = with pkgs; [
    # Required for MCP server operations
    uv
  ];

  # Create MCP configuration directory and files
  home.file.".config/open-webui/mcp-servers.json".text = builtins.toJSON {
    # Filesystem MCP Server - Access to specific directories
    filesystem = {
      command = "uvx";
      args = [
        "mcpo"
        "--port" "8200"
        "--"
        "uvx" 
        "@modelcontextprotocol/server-filesystem"
        config.home.homeDirectory
      ];
      description = "Provides filesystem access to home directory";
      port = 8200;
    };

    # Git MCP Server - Repository insights and operations  
    git = {
      command = "uvx";
      args = [
        "mcpo"
        "--port" "8201" 
        "--"
        "uvx"
        "@modelcontextprotocol/server-git"
      ];
      description = "Provides git repository information and operations";
      port = 8201;
    };

    # Memory MCP Server - Persistent context across sessions
    memory = {
      command = "uvx";
      args = [
        "mcpo"
        "--port" "8202"
        "--"
        "uvx"
        "@modelcontextprotocol/server-memory"
      ];
      description = "Maintains context and memory across sessions";
      port = 8202;
    };

    # Time MCP Server - Date/time operations
    time = {
      command = "uvx";
      args = [
        "mcpo"
        "--port" "8203"
        "--"
        "uvx"
        "mcp-server-time"
        "--local-timezone=America/New_York"
      ];
      description = "Provides date and time information and operations";
      port = 8203;
    };

    # Fetch MCP Server - Web content fetching
    fetch = {
      command = "uvx"; 
      args = [
        "mcpo"
        "--port" "8204"
        "--"
        "uvx"
        "@modelcontextprotocol/server-fetch"
      ];
      description = "Fetches and analyzes web content";
      port = 8204;
    };
  };

  # Create systemd services for MCP servers
  systemd.user.services = {
    mcp-filesystem = {
      Unit = {
        Description = "MCP Filesystem Server for Open WebUI";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.uv}/bin/uvx mcpo --port 8200 -- uvx @modelcontextprotocol/server-filesystem ${config.home.homeDirectory}";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "PATH=${config.home.homeDirectory}/.local/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    mcp-git = {
      Unit = {
        Description = "MCP Git Server for Open WebUI";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.uv}/bin/uvx mcpo --port 8201 -- uvx @modelcontextprotocol/server-git";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "PATH=${config.home.homeDirectory}/.local/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    mcp-memory = {
      Unit = {
        Description = "MCP Memory Server for Open WebUI";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.uv}/bin/uvx mcpo --port 8202 -- uvx @modelcontextprotocol/server-memory";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "PATH=${config.home.homeDirectory}/.local/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    mcp-time = {
      Unit = {
        Description = "MCP Time Server for Open WebUI";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.uv}/bin/uvx mcpo --port 8203 -- uvx mcp-server-time --local-timezone=America/New_York";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "PATH=${config.home.homeDirectory}/.local/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    mcp-fetch = {
      Unit = {
        Description = "MCP Fetch Server for Open WebUI";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.uv}/bin/uvx mcpo --port 8204 -- uvx @modelcontextprotocol/server-fetch";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "PATH=${config.home.homeDirectory}/.local/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  # Create helper scripts for managing MCP servers
  home.file.".local/bin/mcp-start-all".source = pkgs.writeShellScript "mcp-start-all" ''
    #!${pkgs.bash}/bin/bash
    echo "Starting all MCP servers..."
    systemctl --user start mcp-filesystem
    systemctl --user start mcp-git  
    systemctl --user start mcp-memory
    systemctl --user start mcp-time
    systemctl --user start mcp-fetch
    echo "All MCP servers started. Check status with 'mcp-status'"
  '';

  home.file.".local/bin/mcp-stop-all".source = pkgs.writeShellScript "mcp-stop-all" ''
    #!${pkgs.bash}/bin/bash
    echo "Stopping all MCP servers..."
    systemctl --user stop mcp-filesystem
    systemctl --user stop mcp-git
    systemctl --user stop mcp-memory
    systemctl --user stop mcp-time
    systemctl --user stop mcp-fetch
    echo "All MCP servers stopped."
  '';

  home.file.".local/bin/mcp-status".source = pkgs.writeShellScript "mcp-status" ''
    #!${pkgs.bash}/bin/bash
    echo "MCP Server Status:"
    echo "=================="
    systemctl --user status mcp-filesystem --no-pager -l
    systemctl --user status mcp-git --no-pager -l  
    systemctl --user status mcp-memory --no-pager -l
    systemctl --user status mcp-time --no-pager -l
    systemctl --user status mcp-fetch --no-pager -l
    echo ""
    echo "API Endpoints:"
    echo "=============="
    echo "Filesystem API: http://localhost:8200/docs"
    echo "Git API: http://localhost:8201/docs" 
    echo "Memory API: http://localhost:8202/docs"
    echo "Time API: http://localhost:8203/docs"
    echo "Fetch API: http://localhost:8204/docs"
  '';

  # Make scripts executable
  home.file.".local/bin/mcp-start-all".executable = true;
  home.file.".local/bin/mcp-stop-all".executable = true;
  home.file.".local/bin/mcp-status".executable = true;
}