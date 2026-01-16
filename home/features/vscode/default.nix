{
  config,
  pkgs,
  lib,
  ...
}:

let
  marketplaceExtensions = import ./marketplace-extensions.nix;
in
{
  imports = [
    ./custom.theme/themes/theme.json.nix
  ];

  home.file.".config/vscode/plugins/custom.theme/package.json" = {
    force = true;
    source = ./custom.theme/package.json;
  };

  # MCP Configuration
  home.file.".config/Code/User/mcp.json" = {
    force = true;
    text = builtins.toJSON {
      servers = {
        filesystem = {
          command = "npx";
          args = [
            "@modelcontextprotocol/server-filesystem"
            config.home.homeDirectory
          ];
          description = "Provides filesystem access to home directory";
        };
        git = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "--name"
            "mcp-git"
            "-v"
            "${config.home.homeDirectory}:${config.home.homeDirectory}:rw"
            "-v"
            "${config.home.homeDirectory}/.gitconfig:/root/.gitconfig:ro"
            "mcp/git"
          ];
          description = "Provides git repository information and operations";
        };
        memory = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "--name"
            "mcp-memory"
            "-v"
            "mcp-memory-data:/data"
            "mcp/memory"
          ];
          env = {
            DATABASE_URL = "sqlite:///data/memory.db";
          };
          description = "Maintains context and memory across sessions";
        };
        time = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "--name"
            "mcp-time"
            "mcp/time"
            "--local-timezone=America/Chicago"
          ];
          env = {
            TZ = "America/Chicago";
          };
          description = "Provides date and time information and operations";
        };
        fetch = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "--name"
            "mcp-fetch"
            "--network"
            "bridge"
            "mcp/fetch"
          ];
          description = "Fetches and analyzes web content";
        };
        sequential-thinking = {
          command = "npx";
          args = [ "@modelcontextprotocol/server-sequential-thinking@latest" ];
          env = {
            NODE_ENV = "production";
          };
          description = "Helps break down complex problems into sequential steps";
        };
        context7 = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "--name"
            "mcp-context7"
            "mcp/context7"
          ];
          env = {
            CONTEXT7_TOKEN = "$(cat ${config.sops.secrets.context7-token.path})";
            MCP_TRANSPORT = "stdio";
          };
          description = "Provides up-to-date code documentation for AI code editors";
        };
        github = {
          command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
          args = [ "stdio" ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = "$(cat ${config.sops.secrets.github-pat.path})";
            GITHUB_TOOLSETS = "repos,issues,pull_requests,actions,code_security,discussions";
            MCP_TRANSPORT = "stdio";
          };
          description = "GitHub repository and workflow management via MCP";
        };
        playwright = {
          command = "${pkgs.writeShellScriptBin "mcp-server-playwright-nixos" ''
            #!/usr/bin/env bash
            set -euo pipefail

            # Playwright MCP wrapper for NixOS
            # Ensure Playwright can find browsers in NixOS environments

            # Use Playwright's bundled browsers (most reliable)
            export PLAYWRIGHT_BROWSERS_PATH="${lib.getLib pkgs.playwright.browsers}"

            # Try to find system Chrome/Chromium as fallback
            if [ -z "''${PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH:-}" ]; then
              for candidate in google-chrome-stable google-chrome chromium-browser chromium; do
                if target=$(command -v "$candidate" 2>/dev/null); then
                  export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="$target"
                  break
                fi
              done
            fi

            exec ${pkgs.playwright-mcp}/bin/mcp-server-playwright "$@"
          ''}/bin/mcp-server-playwright-nixos";
          args = [ "--headless" ];
          env = {
            PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
          };
          description = "Browser automation and web scraping via Playwright (NixOS-compatible)";
        };
        serena = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "--name"
            "mcp-serena"
            "-v"
            "/home/administrator/Code:/workspace/Code:rw"
            "--network"
            "host"
            "ghcr.io/oraios/serena:latest"
            "serena"
            "start-mcp-server"
            "--transport"
            "stdio"
          ];
          env = {
            SERENA_DOCKER = "1";
          };
          description = "AI-powered development assistant with Code directory access";
        };
        sourcebot = {
          command = "npx";
          args = [ "@sourcebot/mcp@latest" ];
          env = {
            NODE_ENV = "production";
            SOURCEBOT_HOST = "http://localhost:3002";
            SOURCEBOT_API_KEY = "$(cat ${config.sops.secrets."sourcebot/api-key".path})";
          };
          description = "Code understanding and search via Sourcebot";
        };
      };
    };
  };

  home.packages = with pkgs; [
    taplo # Even Better TOML
    nvfetcher # Generate nix sources expr for the latest version of packages
    nil # Nix language server
    nixfmt-rfc-style # Nix formatter
    biome
    vscode-js-debug
    tailwindcss_4
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    profiles = {
      default = {
        enableExtensionUpdateCheck = lib.mkForce false;
        enableUpdateCheck = lib.mkDefault false;
        extensions =
          let
            themeExtension =
              pkgs.runCommandLocal "custom-vscode"
                {
                  vscodeExtUniqueId = "custom.theme";
                  vscodeExtPublisher = "custom";
                  version = "0.0.0";
                }
                ''
                  mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId/themes"
                  ln -s ${config.home.homeDirectory}/.config/vscode/plugins/custom.theme/package.json "$out/share/vscode/extensions/$vscodeExtUniqueId/package.json"
                  ln -s ${config.home.homeDirectory}/.config/vscode/plugins/custom.theme/themes/theme.json "$out/share/vscode/extensions/$vscodeExtUniqueId/themes/theme.json"
                '';
          in
          [
            themeExtension
          ]
          ++ (with pkgs.vscode-extensions; [
            aaron-bond.better-comments
            alefragnani.bookmarks
            bierner.markdown-mermaid
            bradlc.vscode-tailwindcss
            charliermarsh.ruff
            christian-kohler.path-intellisense
            davidanson.vscode-markdownlint
            dbaeumer.vscode-eslint
            donjayamanne.githistory
            eamodio.gitlens
            github.codespaces
            github.copilot
            github.copilot-chat # Use nixpkgs version (0.30.1) for VS Code 1.103.2 compatibility
            github.vscode-github-actions
            github.vscode-pull-request-github
            golang.go
            gruntfuggly.todo-tree
            hashicorp.terraform
            jnoortheen.nix-ide
            jock.svg
            marp-team.marp-vscode
            mikestead.dotenv
            ms-toolsai.jupyter
            ms-kubernetes-tools.vscode-kubernetes-tools
            ms-python.debugpy
            ms-python.vscode-pylance
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.hexeditor
            redhat.vscode-xml
            redhat.vscode-yaml
            rust-lang.rust-analyzer
            samuelcolvin.jinjahtml
            streetsidesoftware.code-spell-checker
            tailscale.vscode-tailscale
            tamasfe.even-better-toml
            usernamehw.errorlens
            yzhang.markdown-all-in-one
          ])
          ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace marketplaceExtensions);
        userSettings = {
          # NOTE: Many project-specific settings have been moved to workspace/folder settings.
          # These include:
          # - Language-specific formatters ([python], [typescript], etc.)
          # - File associations and exclude patterns
          # - Extension-specific settings (Python, Go, Ruff, Tailwind, YAML, etc.)
          # - Editor tab size and rulers (project-specific)
          #
          # To configure these per-project, create .vscode/settings.json in your project root.
          # Example: https://code.visualstudio.com/docs/getstarted/settings#_settings-file-locations

          "accessibility.dimUnfocused.enabled" = true;
          "breadcrumbs.enabled" = true;
          "diffEditor.codeLens" = true;
          "diffEditor.diffAlgorithm" = "advanced";
          "diffEditor.maxFileSize" = 0;
          "diffEditor.renderIndicators" = true;
          "editor.accessibilityPageSize" = 5000;
          "editor.fontFamily" = "FiraCode Nerd Font";
          "editor.experimental.treeSitterTelemetry" = false;
          "editor.foldingMaximumRegions" = 10000;
          "editor.foldingStrategy" = "auto";
          "editor.fontLigatures" = true;
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
          "editor.formatOnType" = true;
          "editor.inlineSuggest.enabled" = true;
          "editor.minimap.enabled" = false;
          "editor.parameterHints.enabled" = true;
          "editor.quickSuggestionsDelay" = 3;
          "editor.renderWhitespace" = "all";
          "editor.semanticHighlighting.enabled" = true;
          "editor.snippetSuggestions" = "top";
          "editor.suggest.localityBonus" = true;
          "editor.suggest.showStatusBar" = true;
          "editor.suggestSelection" = "first";
          "editor.tabCompletion" = "on";
          # Default tab size - projects can override in workspace settings
          "editor.tabSize" = 2;
          "editor.useTabStops" = true;
          "editor.wordBasedSuggestions" = "matchingDocuments";
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = {
            "other" = true;
            "comments" = true;
            "strings" = true;
          };
          # Editor rulers are project-specific - move to workspace settings
          # "editor.rulers" = [ 80 120 ];
          "extensions.autoUpdate" = false;
          "extensions.autoCheckUpdates" = false;
          "update.mode" = "none";

          # File associations, excludes, and watcher excludes are project-specific
          # Move these to workspace settings (.vscode/settings.json) per project
          # "files.associations" = { ... };
          # "files.exclude" = { ... };
          # "files.watcherExclude" = { ... };
          "files.autoSave" = "afterDelay";
          "files.insertFinalNewline" = true;
          "files.trimTrailingWhitespace" = true;
          "security.workspace.trust.untrustedFiles" = "open";
          "telemetry.telemetryLevel" = "off";
          "terminal.integrated.copyOnSelection" = true;
          "terminal.integrated.customGlyphs" = true;
          "terminal.integrated.defaultProfile.linux" = "bash";
          "terminal.integrated.enableImages" = true;
          "terminal.integrated.environmentChangesIndicator" = "off";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
          "terminal.integrated.minimumContrastRatio" = 1;
          "terminal.integrated.mouseWheelZoom" = true;
          "terminal.integrated.scrollback" = 10000;
          "window.newWindowProfile" = "Default";
          "window.titleBarStyle" = "custom";
          "window.zoomLevel" = 2;
          "workbench.colorTheme" = "Custom Theme";
          "workbench.editor.enablePreview" = true;
          "workbench.externalBrowser" = "chrome";

          # Performance and UX improvements
          "editor.bracketPairColorization.enabled" = true;
          "editor.largeFileOptimizations" = true;
          "editor.maxTokenizationLineLength" = 20000;
          "editor.suggest.preview" = true;
          "editor.codeActionWidget.includeNearbyQuickFixes" = true;
          "editor.autoClosingBrackets" = "languageDefined";
          "editor.autoClosingQuotes" = "languageDefined";
          "editor.autoSurround" = "languageDefined";
          "editor.codeLens" = true;
          "editor.colorDecorators" = true;
          "files.hotExit" = "onExit";
          "workbench.startupEditor" = "none"; # Skip welcome page for faster startup
          "workbench.editor.limit.enabled" = true; # Limit open editors for performance
          "workbench.editor.limit.value" = 20; # Max 20 open editors

          # "remote.defaultExtensionsIfInstalledLocally" = [
          #   "GitHub.copilot"
          #   "GitHub.copilot-chat"
          #   "GitHub.vscode-pull-request-github"
          # ];

          #############################
          #    Extension Settings     #
          #############################

          ##### Autodoc Strings #####
          # "autoDocstring.docstringFormat" = "google";
          # "autoDocstring.generateDocstringOnEnter" = true;
          # "autoDocstring.guessTypes" = true;
          # "autoDocstring.startOnNewLine" = true;

          "emmet.showSuggestionsAsSnippets" = true;
          "emmet.includeLanguages" = {
            "javascript" = "javascriptreact";
            "typescript" = "typescriptreact";
            "vue-html" = "html";
            "templ" = "html";
          };
          "emmet.triggerExpansionOnTab" = true;

          ##### Code Runner ####

          #####  Copilot #####
          # "github.copilot.chat.temporalContext.enabled" = true;
          "github.copilot.chat.startDebugging.enabled" = true;
          "github.copilot.chat.localeOverride" = "en";
          "github.copilot.chat.useProjectTemplates" = true;
          "github.copilot.editor.enableCodeActions" = true;
          "github.copilot.renameSuggestions.triggerAutomatically" = true;
          "github.copilot.advanced" = {
            "listCount" = 3;
          };
          "github.copilot.enable" = {
            "*" = true;
            "plaintext" = false;
          };
          "github.copilot.chat.editor.temporalContext.enabled" = true;

          ##### MCP (Model Context Protocol) Settings #####
          # MCP Core Settings
          "chat.mcp.enabled" = true; # Enable MCP functionality
          "chat.mcp.autostart" = "newAndOutdated"; # Auto-start MCP servers (vs "never")
          "chat.mcp.discovery.enabled" = true; # Enable MCP server discovery

          # Disable specific MCP features
          "chat.mcp.assisted.nuget.enabled" = false; # Disable NuGet assistance (not needed)

          # MCP Server Sampling (empty = use defaults)
          "chat.mcp.serverSampling" = { };

          # Context7 Integration
          "github.copilot.chat.newWorkspace.useContext7" = true; # Enable Context7 for new workspaces

          ###  Chatgpt - Codex ###
          "chatgpt.openOnStartup" = true;

          #####  Dev Containers #####
          # "dev.containers.defaultExtensionsIfInstalledLocally" = [
          #   "GitHub.copilot"
          #   "GitHub.copilot-chat"
          #   "GitHub.vscode-pull-request-github"
          # ];
          "dotfiles.repository" = "https://github.com/ryanwclark1/dotfiles.git";
          "dotfiles.installCommand" = "bootstrap.sh";

          ##### Nix IDE #####
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";
          "nix.serverSettings" = {
            "nil" = {
              "formatting" = {
                "command" = [ "nixfmt-rfc-style" ];
              };
              "diagnostics" = {
                "ignored" = [
                  "unused_binding"
                  "unused_with"
                ];
              };
              "nixpkgs" = {
                "expr" =
                  "import (builtins.getFlake \"${config.home.homeDirectory}/nixos-config\").inputs.nixpkgs {}";
              };
              "options" = {
                "nixos" = {
                  "expr" =
                    "(builtins.getFlake \"${config.home.homeDirectory}/nixos-config\").nixosConfigurations.<name>.options";
                };
                "home-manager" = {
                  "expr" =
                    "(builtins.getFlake \"${config.home.homeDirectory}/nixos-config\").homeConfigurations.<name>.options";
                };
              };
            };
          };
          # "[nix]" = {
          #   "editor.defaultFormatter" = "jnoortheen.nix-ide";
          #   "editor.formatOnSave" = true;
          # };

          ##### Redhat #####
          "redhat.telemetry.enabled" = false;

          ##### Ruff #####
          # Most Ruff settings are project-specific - move to workspace settings
          # Keep only global enable/disable preference
          "ruff.enable" = true;
          # "ruff.importStrategy" = "fromEnvironment";
          # "ruff.lineLength" = 88;
          # "ruff.organizeImports" = true;
          # "ruff.fixAll" = true;
          # "ruff.configurationPreference" = "filesystemFirst";

          ##### GO #####
          # Go settings are project-specific - move to workspace settings
          # Keep only minimal global preferences if needed
          # "go.delveConfig" = { ... };
          # "go.editorContextMenuCommands" = { ... };
          # "go.enableCodeLens" = { ... };
          # "go.playground" = { ... };
          # "go.lintOnSave" = "workspace";
          # "go.inferGopath" = true;
          # "go.showWelcome" = false;
          # "go.survey.prompt" = false;
          # "go.tasks.provideDefault" = true;
          # "go.terminal.activateEnvironment" = true;
          # "go.testExplorer.enable" = true;
          # "go.testExplorer.alwaysRunBenchmarks" = true;
          # "go.testExplorer.concatenateMessages" = true;
          # "go.testExplorer.packageDisplayMode" = "nested";
          # "go.testExplorer.showDynamicSubtestsInEditor" = false;
          # "go.testExplorer.showOutput" = true;
          # "go.testTimeout" = "30s";
          # "go.trace.server" = "messages";
          # "go.useLanguageServer" = true;
          # "gopls" = { ... };

          ##### Postgres #####
          "pgsql.copilot.enable" = true;

          ##### Python #####
          # Python settings are highly project-specific - move to workspace settings
          # Keep only minimal global preferences
          # "python.testing.autoTestDiscoverOnSaveEnabled" = true;
          # "python.testing.pytestEnabled" = true;
          # "python.testing.unittestEnabled" = false;
          # "python.analysis.*" = { ... };
          # "python.createEnvironment.contentButton" = "show";
          # "python.terminal.shellIntegration.enabled" = true;
          # "python.venvFolders" = [ ".venv" ];

          # Language-specific formatter settings are project-specific
          # Move these to workspace settings (.vscode/settings.json) per project
          # Examples:
          # "[python]" = { "editor.defaultFormatter" = "..."; "editor.tabSize" = 4; };
          # "[typescript]" = { "editor.defaultFormatter" = "biomejs.biome"; };
          # "[javascript]" = { "editor.defaultFormatter" = "biomejs.biome"; };
          # "[yaml]" = { "editor.tabSize" = 2; };
          # etc.

          ##### Git #####
          "git.autofetch" = true;
          "git.autofetchPeriod" = 30;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;

          ##### Github #####
          # "github.codespaces.defaultExtensions" = [
          #   "GitHub.codespaces"
          #   "GitHub.vscode-pull-request-github"
          #   "Github.copilot-chat"
          #   "Github.copilot"
          # ];

          ##### Kubernetes #####
          # "vs-kubernetes" = {
          #   "vs-kubernetes.crd-code-completion" = "enabled";
          # };
          # "vscode-kubernetes.log-viewer.autorun" = true;
          # "vscode-kubernetes.log-viewer.destination" = "Terminal";
          # "vscode-kubernetes.log-viewer.follow" = true;
          # "vscode-kubernetes.log-viewer.timestamp" = true;

          ##### CSS #####
          # "[css]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

          ##### Tailwind CSS #####
          # Tailwind CSS settings are project-specific - move to workspace settings
          # "tailwindCSS.includeLanguages" = { ... };
          # "tailwindCSS.codeActions" = true;
          # etc.

          ##### Templ #####
          # Templ settings are project-specific - move to workspace settings
          # "templ.pprof" = true;
          # "templ.goplsRPCTrace" = true;

          ##### YAML #####
          # YAML settings are project-specific - move to workspace settings
          # "yaml.completion" = true;
          # "yaml.format.*" = { ... };
          # etc.
        };
      };
    };
  };
}
