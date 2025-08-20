{
  pkgs,
  config,
  ...
}: {
  # MCP Server packages
  # nodejs_22 is provided by development/js.nix

  # MCP Server configurations for VSCode
  # These servers provide additional context and capabilities to GitHub Copilot
  programs.vscode.profiles.default.userSettings = {
    "github.copilot.chat.mcpServers.servers" = {
      # Filesystem MCP Server - Access to specific directories
      "filesystem" = {
        "command" = "npx";
        "args" = [
          "@modelcontextprotocol/server-filesystem"
          config.home.homeDirectory
        ];
        "description" = "Provides filesystem access to home directory";
      };

      # Git MCP Server - Repository insights and operations
      "git" = {
        "command" = "npx";
        "args" = ["@modelcontextprotocol/server-git"];
        "description" = "Provides git repository information and operations";
      };

      # Memory MCP Server - Persistent context across sessions
      "memory" = {
        "command" = "npx";
        "args" = ["@modelcontextprotocol/server-memory"];
        "description" = "Maintains context and memory across Copilot sessions";
      };

      # SQLite MCP Server - Database access
      # "sqlite" = {
      #   "command" = "npx";
      #   "args" = [
      #     "@modelcontextprotocol/server-sqlite"
      #     "/path/to/your/database.db"
      #   ];
      #   "description" = "Provides SQLite database access";
      # };

      # GitHub MCP Server - Enhanced GitHub integration
      # Requires GITHUB_TOKEN environment variable
      # "github" = {
      #   "command" = "npx";
      #   "args" = ["@modelcontextprotocol/server-github"];
      #   "env" = {
      #     "GITHUB_TOKEN" = "ghp_YOUR_GITHUB_TOKEN_HERE";
      #   };
      #   "description" = "Enhanced GitHub repository insights and operations";
      # };

      # Playwright MCP Server - Frontend testing and verification
      # "playwright" = {
      #   "command" = "npx";
      #   "args" = ["@modelcontextprotocol/server-playwright"];
      #   "description" = "Browser automation and frontend verification";
      # };

      # PostgreSQL MCP Server - PostgreSQL database access
      # "postgres" = {
      #   "command" = "npx";
      #   "args" = ["@modelcontextprotocol/server-postgres"];
      #   "env" = {
      #     "POSTGRES_CONNECTION_STRING" = "postgresql://user:password@localhost/dbname";
      #   };
      #   "description" = "PostgreSQL database access";
      # };

      # Puppeteer MCP Server - Alternative browser automation
      # "puppeteer" = {
      #   "command" = "npx";
      #   "args" = ["@modelcontextprotocol/server-puppeteer"];
      #   "description" = "Browser automation using Puppeteer";
      # };

      # Sequential Thinking MCP Server - Step-by-step problem solving
      # "sequential-thinking" = {
      #   "command" = "npx";
      #   "args" = ["@modelcontextprotocol/server-sequential-thinking"];
      #   "description" = "Helps break down complex problems into steps";
      # };

      # Fetch MCP Server - Web content fetching
      # "fetch" = {
      #   "command" = "npx";
      #   "args" = ["@modelcontextprotocol/server-fetch"];
      #   "description" = "Fetches and analyzes web content";
      # };
    };
  };
}