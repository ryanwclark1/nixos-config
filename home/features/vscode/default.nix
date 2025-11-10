{
  config,
  pkgs,
  lib,
  ...
}:

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
        command = "docker";
        args = [
          "run"
          "-i"
          "--rm"
          "--name"
          "mcp-github"
          "ghcr.io/github/github-mcp-server"
        ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "$(cat ${config.sops.secrets.github-pat.path})";
          GITHUB_TOOLSETS = "repos,issues,pull_requests,actions,code_security,discussions";
          MCP_TRANSPORT = "stdio";
        };
        description = "GitHub repository and workflow management via MCP";
      };
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
        args = [ "--headless" ];
        description = "Browser automation and web scraping via Playwright";
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
            # esbenp.prettier-vscode  # Removed: conflicts with biomejs.biome
            # formulahendry.code-runner  # Removed: interferes with proper debugging workflows
            github.codespaces
            github.copilot
            github.copilot-chat  # Use nixpkgs version (0.30.1) for VS Code 1.103.2 compatibility
            github.vscode-github-actions
            github.vscode-pull-request-github
            golang.go
            gruntfuggly.todo-tree
            # griimick.vhs  # Removed: very niche terminal GIF recording tool
            hashicorp.terraform
            # hediet.vscode-drawio  # Removed: only needed for diagram creation
            # jetmartin.bats  # Removed: only needed for Bash testing
            jnoortheen.nix-ide
            jock.svg
            marp-team.marp-vscode
            # ms-kubernetes-tools.vscode-kubernetes-tools  # Disabled: no active K8s clusters
            # ms-python.black-formatter  # Removed: Ruff handles formatting
            mikestead.dotenv
            ms-toolsai.jupyter
            ms-kubernetes-tools.vscode-kubernetes-tools
            ms-python.debugpy
            # ms-python.isort  # Removed: Ruff handles import sorting
            # ms-python.python  # Moved to extensionsFromVscodeMarketplace for version control
            ms-python.vscode-pylance
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.hexeditor
            # ms-vscode.live-server  # Removed: modern frameworks have better dev servers
            # quicktype.quicktype  # Removed: niche JSON-to-types conversion
            redhat.vscode-xml
            redhat.vscode-yaml
            rust-lang.rust-analyzer
            samuelcolvin.jinjahtml
            streetsidesoftware.code-spell-checker
            # shyykoserhiy.vscode-spotify  # Removed: non-development related
            tailscale.vscode-tailscale
            tamasfe.even-better-toml
            usernamehw.errorlens  # Removed: can be visually noisy
            yzhang.markdown-all-in-one
          ])
          ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # {
          #   name = "alpine-js-intellisense";
          #   publisher = "adrianwilczynski";
          #   sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
          #   version = "1.2.0";
          # }
          # {
          #   name = "ansible";
          #   publisher = "redhat";
          #   sha256 = "sha256-Z0oUhqoHfVALG5k1dbSBpJiq0AEjaqeh8yLJ8FjvfcY=";
          #   version = "25.9.0";
          # }
          {
            name = "biome";
            publisher = "biomejs";
            sha256 = "sha256-tihEFcDDYr/khLIcJbR5VSC/RujEvp/gcnWlokAqNBc=";
            version = "2025.10.241456";
          }
          {
            name = "chatgpt";
            publisher = "openai";
            sha256 = "sha256-xDynv+0LYr3OTpZzFOllJLO4Vn35Iyrfi7YHcfjJrjI=";
            version = "0.5.38";
          }
          {
            name = "claude-code";
            publisher = "anthropic";
            sha256 = "sha256-1wN82mZk3zCGGFQ8FNwLFm1793U8GEC8p46BJiPNaUo=";
            version = "2.0.35";
          }
          # {
          #   name = "context7-mcp";
          #   publisher = "upstash";
          #   sha256 = "sha256-q6SkIy7eZ9H1yOnZygkcXQcpTK4eu6/jjud1wqEL2Mw=";
          #   version = "1.0.1";
          # }
          # {
          #   name = "copilot";
          #   publisher = "github";
          #   sha256 = "sha256-7RjK8+PNI+rIuRQfCwpvswAiz991dacRO2qYhcv1vhk=";
          #   version = "1.388.0";
          # }
          # {
          #   name = "copilot-chat";
          #   publisher = "github";
          #   sha256 = "sha256-EinZRjMJ0kndrWL824TVPBK2Q7jLZSLjEjyD281Xevk=";
          #   version = "0.33.2025111002";
          # }
          {
            name = "explorer";
            publisher = "vitest";
            sha256 = "sha256-MAfjS/oFfFuiE+Q2w6leSlao436QSw2fKjd7/BE/Q8Y=";
            version = "1.32.1";
          }
          {
            name = "gemini-cli-vscode-ide-companion";
            publisher = "Google";
            sha256 = "sha256-VzaCRe6yqyQ8+z3NWMPk0T7Zd2+xh6z684wt0SabGhE=";
            version = "0.7.0";
          }
          {
            name = "grafana-alloy";
            publisher = "grafana";
            sha256 = "sha256-XcoiEDCPp6GzYQDhJArZBEWxSnZrSTHofIyLFegsbh0=";
            version = "0.2.0";
          }
          {
            name = "grafana-vscode";
            publisher = "grafana";
            sha256 = "sha256-TpLOMwdaEdgzWVwUcn+fO4rgLiQammWQM8LQobt8gLw=";
            version = "0.0.19";
          }
          # {
          #   name = "htmx-attributes";
          #   publisher = "craigrbroughton";
          #   sha256 = "sha256-TsemPZkq2Z13/vahRaP7z206BJaCZ1TR6OVv6aeDvyk=";
          #   version = "0.8.0";
          # }
          {
            name = "hyprland";
            publisher = "ewen-lbh";
            sha256 = "sha256-GaDpbkqNyIElSBnHwxc2ntmEVAGwL9XlNIBWNo7pvwM=";
            version = "0.1.2";
          }
          {
            name = "mypy-type-checker";
            publisher = "ms-python";
            sha256 = "sha256-qVYgUZV2HgzYxL3dGEtOdx2pQE+QOSKMhhpiBLeBpZA=";
            version = "2025.3.12581007";
          }
          {
            name = "pdf";
            publisher = "tomoki1207";
            sha256 = "sha256-i3Rlizbw4RtPkiEsodRJEB3AUzoqI95ohyqZ0ksROps=";
            version = "1.2.2";
          }
          {
            name = "playwright";
            publisher = "ms-playwright";
            sha256 = "sha256-t5PJtBDkjh80IhOpfjsX8kZCSfhGoQ1dePEYMYgw66c=";
            version = "1.1.16";
          }
          {
            name = "prom";
            publisher = "ventura";
            sha256 = "sha256-h8pRrPzmu8+5ZiOLALjackr4zWuFAqi1ex7Gp2iOZKk=";
            version = "1.3.3";
          }
          # {
          #   name = "pwc";
          #   publisher = "SureshNettur";
          #   sha256 = "sha256-qVKs90Dd5ejgzYK7ptGBloU/aPuZ1Nm/ydidSDJwq2I=";
          #   version = "1.1.0";
          # }
          {
            name = "remotehub";
            publisher = "GitHub";
            sha256 = "sha256-boKDVKLo8Na799OtoPnT6JxsAvQ/HoqL3FispnN6bOA=";
            version = "0.65.2025081801";
          }
          # {
          #   name = "snyk-vulnerability-scanner";
          #   publisher = "snyk-security";
          #   sha256 = "sha256-f+x4ZgrRVpfherVX87AFHT0xEZKJukW7waYU2P3uyyo=";
          #   version = "2.26.0";
          # }
          # {
          #   name = "specstory-vscode";
          #   publisher = "specstory";
          #   sha256 = "sha256-u0y4NvZapJT/Mu7mVdCQ9mBTZwSwALnzV33PChzTnfM=";
          #   version = "0.24.2";
          # }
          # {
          #   name = "tailwind-color-matcher";
          #   publisher = "OmriGrossman";
          #   sha256 = "sha256-WfFg1h5tY43W9YqgXkHDlxjRquFupuvLBwotTw0XoNk=";
          #   version = "1.0.8";
          # }
          # {
          #   name = "tailwind-fold";
          #   publisher = "stivo";
          #   sha256 = "sha256-yH3eA5jgBwxqnpFQkg91KQMkQps5iM1v783KQkQcWUU=";
          #   version = "0.2.0";
          # }
          {
            name = "templ";
            publisher = "a-h";
            sha256 = "sha256-WIBJorljcnoPUrQCo1eyFb6vQ5lcxV0i+QJlJdzZYE0=";
            version = "0.0.35";
          }
          # {
          #   name = "ty";
          #   publisher = "astral-sh";
          #   sha256 = "sha256-gkJtg0ncV46UNBiupxnetytCNfZJ2L9iSqpMyvmDftU=";
          #   version = "2025.51.13022037";
          # }
          {
            name = "vscode-containers";
            publisher = "ms-azuretools";
            sha256 = "sha256-UxWsu7AU28plnT0QMdpPJrcYZIV09FeC+rmYKf39a6M=";
            version = "2.2.0";
          }
          {
            name = "vscode-gitops-tools";
            publisher = "weaveworks";
            sha256 = "sha256-7MCKDnHCot/CL/SqZ2WuTxbqFdF75EC5WC+OxW0dcaE=";
            version = "0.27.0";
          }
          {
            name = "vscode-jsonnet";
            publisher = "grafana";
            sha256 = "sha256-Q8VzXzTdHo9h5+eCHHF1bPomPEbRsvouJcUfmFUDGMU=";
            version = "0.7.2";
          }
          {
            name = "vscode-pgsql";
            publisher = "ms-ossdata";
            sha256 = "sha256-BoL0DM0r8gnSmehDUHSS2i4UuEATsCni3rlMVM0OWXo=";
            version = "1.11.3";
          }
          {
            name = "vscode-python-test-adapter";
            publisher = "littlefoxteam";
            sha256 = "sha256-TwBPGr8bam1NSX2KRrm92DOQWeVa0k+pXT4q/isWYOI=";
            version = "0.8.2";
          }
          {
            name = "vscode-thunder-client";
            publisher = "rangav";
            sha256 = "sha256-Eg10vZTq76LmXpUwzGcLGRFzT9RKZvlhJvhf8lA0u5c=";
            version = "2.38.4";
          }
          ]);
        userSettings = {
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
          "editor.tabSize" = 2;
          "editor.useTabStops" = true;
          "editor.wordBasedSuggestions" = "matchingDocuments";
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = {
            "other" = true;
            "comments" = true;
            "strings" = true;
          };
          "editor.rulers" = [
            80
            120
          ];
          "extensions.autoUpdate" = false;
          "extensions.autoCheckUpdates" = false;
          "update.mode" = "none";

          "files.associations" = {
            "*.css" = "tailwindcss";
            ".env" = "dotenv";
            ".env*" = "dotenv";
          };
          "files.exclude" = {
            "**/node_modules/**" = true;
            "**/venv/**" = true;
            "**/.venv/**" = true;
            ".git" = true;
            "**/.git" = false;
          };
          "files.watcherExclude" = {
            "**/.git/objects/**" = true;
            "**/.git/subtree-cache/**" = true;
            "**/node_modules/*/**" = true; # Note: your original had '**/node_modules/**', this is slightly more specific
            "**/__pycache__/**" = true;
            "**/.pytest_cache/**" = true;
            "**/dist/**" = true;
            "**/build/**" = true;
            "**/.venv/**" = true;
            "**/.ruff_cache/**" = true;
          };
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
          "chat.mcp.enabled" = true;  # Enable MCP functionality
          "chat.mcp.autostart" = "newAndOutdated";  # Auto-start MCP servers (vs "never")
          "chat.mcp.discovery.enabled" = true;  # Enable MCP server discovery

          # Disable specific MCP features
          "chat.mcp.assisted.nuget.enabled" = false;  # Disable NuGet assistance (not needed)

          # MCP Server Sampling (empty = use defaults)
          "chat.mcp.serverSampling" = {};

          # Context7 Integration
          "github.copilot.chat.newWorkspace.useContext7" = true;  # Enable Context7 for new workspaces

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
          "ruff.enable" = true;
          "ruff.importStrategy" = "fromEnvironment";
          "ruff.lineLength" = 88;
          "ruff.organizeImports" = true;
          "ruff.fixAll" = true;
          "ruff.configurationPreference" = "filesystemFirst";

          ##### GO #####
          "go.delveConfig" = {
            "apiVersion" = 2;
            "debugAdapter" = "dlv-dap";
            "showLog" = true;
          };
          "go.editorContextMenuCommands" = {
            "addImport" = true;
            "addTags" = true;
            "benchmarkAtCursor" = false;
            "debugTestAtCursor" = true;
            "fillStruct" = false;
            "generateTestForFile" = false;
            "generateTestForFunction" = true;
            "generateTestForPackage" = false;
            "playground" = true;
            "removeTags" = false;
            "testAtCursor" = true;
            "testCoverage" = true;
            "testFile" = false;
            "testPackage" = false;
            "toggleTestFile" = true;
          };
          "go.enableCodeLens" = {
            "runtest" = true;
          };
          "go.playground" = {
            "openbrowser" = true;
            "run" = true;
            "share" = true;
          };
          "go.lintOnSave" = "workspace";
          "go.inferGopath" = true;
          "go.showWelcome" = false;
          "go.survey.prompt" = false;
          "go.tasks.provideDefault" = true;
          "go.terminal.activateEnvironment" = true;
          "go.testExplorer.enable" = true;
          "go.testExplorer.alwaysRunBenchmarks" = true;
          "go.testExplorer.concatenateMessages" = true;
          "go.testExplorer.packageDisplayMode" = "nested";
          "go.testExplorer.showDynamicSubtestsInEditor" = false;
          "go.testExplorer.showOutput" = true;
          "go.testTimeout" = "30s";
          "go.trace.server" = "messages";
          "go.useLanguageServer" = true;
          "gopls" = {
            "build.directoryFilters" = [
              "-**/node_modules"
            ];
            "formatting.gofumpt" = true;
            "formatting.templateExtensions" = [
              "tmpl"
            ];
            "ui.codelenses" = {
              "generate" = true;
              "gc_details" = true;
              "regenerate_cgo" = true;
              "run_govulncheck" = false;
              "test" = true;
              "tidy" = true;
              "upgrade_dependency" = true;
              "vendor" = true;
            };
            "ui.completion.completeFunctionCalls" = true;
            "ui.completion.experimentalPostfixCompletions" = true;
            "ui.completion.matcher" = "Fuzzy";
            "ui.completion.usePlaceholders" = true;
            "ui.diagnostic.analysisProgressReporting" = true;
            "ui.diagnostic.diagnosticsTrigger" = "Edit";
            "ui.diagnostic.hoverKind" = "Structured";
            "ui.diagnostic.staticcheck" = true;
            "ui.navigation.importShortcut" = "Both";
            "ui.navigation.symbolMatcher" = "Fuzzy";
            "ui.navigation.symbolScope" = "all";
            "ui.navigation.symbolStyle" = "Dynamic";
            "ui.semanticTokens" = true;
          };

          ##### Postgres #####
          "pgsql.copilot.enable" = true;

          ##### Python #####
          "python.testing.autoTestDiscoverOnSaveEnabled" = true; # Updated from false
          "python.testing.pytestEnabled" = true;
          "python.testing.unittestEnabled" = false;

          # Python specific settings
          "python.analysis.aiCodeActions" = {
            "convertFormatString" = true;
            "implementAbstractClasses" = true;
            "convertLambdaToNamedFunction" = true;
            "generateDocstring" = true;
            "generateSymbol" = true;
          };
          "python.analysis.autoFormatStrings" = true;
          "python.analysis.autoImportCompletions" = true;
          "python.analysis.cacheLSPData" = true;
          "python.analysis.completeFunctionParens" = true;
          "python.analysis.disableTaggedHints" = true;
          "python.analysis.enableColorPicker" = true;
          "python.analysis.enablePytestSupport" = true;
          "python.analysis.exclude" = [
            "**/node_modules"
            "**/__pycache__"
            "**/.ruff_cache"
            "**/.pytest_cache"
            "**/.mypy_cache"
            "**/.venv"
            "**/.venv*"
          ];
          "python.analysis.generateWithTypeAnnotation" = true;
          "python.analysis.fixAll" = [
            "source.convertImportFormat"
            "source.unusedImports"
          ];
          "python.analysis.inlayHints.callArgumentNames" = "all";
          "python.analysis.inlayHints.functionReturnTypes" = true;
          "python.analysis.inlayHints.pytestParameters" = true;
          "python.analysis.inlayHints.variableTypes" = true;
          "python.analysis.regenerateStdLibIndices" = true;
          "python.analysis.supportAllPythonDocuments" = true;
          "python.analysis.supportDocstringTemplate" = true;
          "python.analysis.supportRestructuredText" = true;
          "python.analysis.typeEvaluation.deprecateTypingAliases" = true;
          "python.analysis.typeEvaluation.enableReachabilityAnalysis" = true;
          "python.analysis.typeEvaluation.strictDictionaryInference" = true;
          "python.analysis.typeEvaluation.strictListInference" = true;
          "python.analysis.typeEvaluation.strictSetInference" = true;
          "python.analysis.typeshedPaths" = [ "typings" ];
          "python.analysis.include" = [ "**/*.py" ];
          "python.analysis.autoSearchPaths" = true;
          "python.analysis.nodeArguments" = [
            "--max-old-space-size=16384"
          ];
          "python.analysis.userFileIndexingLimit" = -1;

          "python.createEnvironment.contentButton" = "show";
          "python.terminal.shellIntegration.enabled" = true;
          "python.venvFolders" = [ ".venv" ];

          ##### Docker Compose #####

          "[dockercompose]" = {
            "editor.autoIndent" = "advanced";
            "editor.defaultFormatter" = "redhat.vscode-yaml";
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.quickSuggestions" = {
              "other" = true;
              "comments" = false;
              "strings" = true;
            };
            "editor.tabSize" = 4;
          };

          "[dockerfile]" = {
            "editor.formatOnSave" = true;
          };

          "[github-actions-workflow]" = {
            "editor.autoIndent" = "advanced";
            "editor.insertSpaces" = true;
            "editor.quickSuggestions" = {
              "other" = true;
              "comments" = false;
              "strings" = true;
            };
            "editor.tabSize" = 2;
          };

          "[json][jsonc]" = {
            "editor.defaultFormatter" = "vscode.json-language-features";
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 4;
          };
          "[python]" = {
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
              "source.organizeImports" = "explicit";
            };
            "editor.formatOnSave" = true;
            "editor.tabSize" = 4;
          };
          "[toml]" = {
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 4;
          };
          "[yaml]" = {
            "editor.autoIndent" = "advanced";
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
          };

          ##### Typescript #####
          "[javascript]" = {
            "editor.defaultFormatter" = "biomejs.biome";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = "explicit";
            };
          };
          "[typescript]" = {
            "editor.defaultFormatter" = "biomejs.biome";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = "explicit";
            };
          };
          "[typescriptreact]" = {
            "editor.defaultFormatter" = "biomejs.biome";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = "explicit";
            };
          };
          "[javascriptreact]" = {
            "editor.defaultFormatter" = "biomejs.biome";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = "explicit";
            };
          };

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


          ##### Snyk #####
          # "snyk.advanced.cliPath" = "${config.home.homeDirectory}/.local/share/snyk/vscode-cli/snyk-linux";
          # "snyk.folderConfigs" = [
          #   {
          #     "baseBranch" = "main";
          #     "folderPath" = "${config.home.homeDirectory}/nixos-config";
          #     "localBranches" = [
          #       "main"
          #     ];
          #   }
          # ];

          ##### CSS #####
          # "[css]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

          ##### Tailwind CSS #####
          # Configurations: https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss
          "tailwindCSS.includeLanguages" = {
            "plaintext" = "html";
            "templ" = "html";
            "vue-html" = "html";
            "javascript" = "javascriptreact";
            "typescript" = "typescriptreact";
            "svelte" = "html";
          };
          "tailwindCSS.codeActions" = true;
          "tailwindCSS.colorDecorators" = true;
          "tailwindCSS.emmetCompletions" = true;
          "tailwindCSS.hovers" = true;
          "tailwindCSS.showPixelEquivalents" = true;
          "tailwindCSS.suggestions" = true;
          "tailwindCSS.validate" = true;

          ##### Templ #####
          "templ.pprof" = true;
          "templ.goplsRPCTrace" = true;

          ##### YAML #####
          "yaml.completion" = true;
          "yaml.extension.recommendations" = true;
          "yaml.format.bracketSpacing" = true;
          "yaml.format.enable" = true;
          "yaml.format.printWidth" = 80;
          "yaml.format.proseWrap" = "preserve";
          "yaml.hover" = true;
          "yaml.maxItemsComputed" = 5000;
          "yaml.schemaStore.enable" = true;
          "yaml.schemaStore.url" = "https://www.schemastore.org/api/json/catalog.json";
          "yaml.validate" = true;
          "yaml.yamlVersion" = "1.2";
        };
      };
    };
  };
}
