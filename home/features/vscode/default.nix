{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./custom.theme/themes/theme.json.nix ];

  home.file.".config/vscode/plugins/custom.theme/package.json" = {
    source = ./custom.theme/package.json;
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
            bierner.markdown-mermaid
            bradlc.vscode-tailwindcss
            charliermarsh.ruff
            dbaeumer.vscode-eslint
            donjayamanne.githistory
            esbenp.prettier-vscode
            formulahendry.code-runner
            github.codespaces
            github.vscode-github-actions
            github.vscode-pull-request-github
            golang.go
            griimick.vhs
            hashicorp.terraform
            hediet.vscode-drawio
            jetmartin.bats
            jnoortheen.nix-ide
            jock.svg
            marp-team.marp-vscode
            ms-kubernetes-tools.vscode-kubernetes-tools
            ms-python.black-formatter
            ms-python.debugpy
            ms-python.isort
            ms-python.python
            ms-python.vscode-pylance
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.hexeditor
            ms-vscode.live-server
            quicktype.quicktype
            redhat.vscode-xml
            redhat.vscode-yaml
            samuelcolvin.jinjahtml
            shyykoserhiy.vscode-spotify
            tailscale.vscode-tailscale
            tamasfe.even-better-toml
            usernamehw.errorlens
            yzhang.markdown-all-in-one
          ])
          ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "alpine-js-intellisense";
            publisher = "adrianwilczynski";
            sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
            version = "1.2.0";
          }
          {
            name = "ansible";
            publisher = "redhat";
            sha256 = "sha256-E/BogNtax4dkv6hlYcaRinTxr4jnVyV9hVCdkIkul9s=";
            version = "25.4.0";
          }
          {
            name = "biome";
            publisher = "biomejs";
            sha256 = "sha256-k0/aQnkHSICIQ5n6CSUGF0Z/HiTeet0BCf0UxQRxq7g=";
            version = "2025.5.251939";
          }
          {
            name = "claude-code-chat";
            publisher = "AndrePimenta";
            sha256 = "sha256-1tgTQrWAN+y+b9eehp8iwsVLwTyr/hR6w6fKXRmCih8=";
            version = "0.1.2";
          }
          {
            name = "claude-dev";
            publisher = "saoudrizwan";
            sha256 = "sha256-1OQoo48B7HAqY64b+hEMU4Wl3PCDcs2LjQBDfyt3elM=";
            version = "3.17.15";
          }
          {
            name = "copilot";
            publisher = "github";
            sha256 = "sha256-7IiYfOX3Xl3cW5FcG+7FjGAmkw7Wa9802eguRmaFE5Y=";
            version = "1.336.0";
          }
          {
            name = "explorer";
            publisher = "vitest";
            sha256 = "sha256-8W30ouGXUCRNiRwNAhK0WREj7Pnhz2PVtj38bpH1WNU=";
            version = "1.26.0";
          }
          {
            name = "grafana-vscode";
            publisher = "grafana";
            sha256 = "sha256-TpLOMwdaEdgzWVwUcn+fO4rgLiQammWQM8LQobt8gLw=";
            version = "0.0.19";
          }
          {
            name = "htmx-attributes";
            publisher = "craigrbroughton";
            sha256 = "sha256-TsemPZkq2Z13/vahRaP7z206BJaCZ1TR6OVv6aeDvyk=";
            version = "0.8.0";
          }
          {
            name = "mypy-type-checker";
            publisher = "ms-python";
            sha256 = "sha256-HdciyEMybqkXMF8mixNHn/GYnHQv46XOrhZ5iJHya7Q=";
            version = "2025.3.11071011";
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
            sha256 = "sha256-1fdUyzJitFfl/cVMOjEiuBS/+FTGttilXoZ8txZMmVs=";
            version = "1.1.15";
          }
          {
            name = "prom";
            publisher = "ventura";
            sha256 = "sha256-h8pRrPzmu8+5ZiOLALjackr4zWuFAqi1ex7Gp2iOZKk=";
            version = "1.3.3";
          }
          {
            name = "pwc";
            publisher = "SureshNettur";
            sha256 = "sha256-e9Z6PZQ8yWs83jpBuVdBLlePOYO0qUvBcbYkOOc4vVI=";
            version = "1.0.1";
          }
          {
            name = "remotehub";
            publisher = "GitHub";
            sha256 = "sha256-Xb28yff0tiQDUuwC5Mv0rwXqLgZOU4B3KZAht78NfFU=";
            version = "0.65.2024112101";
          }
          {
            name = "snyk-vulnerability-scanner";
            publisher = "snyk-security";
            sha256 = "sha256-IaFwA5qPkL2zCq1uTrAeEcOIeAb/T+7QP2tqdiGcpeU=";
            version = "2.22.0";
          }
          {
            name = "specstory-vscode";
            publisher = "specstory";
            sha256 = "sha256-g8hyeunCErKW4l8lEd7QBsohuOi2iSJoaBod46xoBOA=";
            version = "0.12.1";
          }
          {
            name = "sqlite-viewer";
            publisher = "qwtel";
            sha256 = "sha256-fgt7UE363q0cqaVU0D628c+MX/ZkIhdbJFz2x2G9j5o=";
            version = "25.6.0";
          }
          {
            name = "tailwind-color-matcher";
            publisher = "OmriGrossman";
            sha256 = "sha256-WfFg1h5tY43W9YqgXkHDlxjRquFupuvLBwotTw0XoNk=";
            version = "1.0.8";
          }
          {
            name = "tailwind-fold";
            publisher = "stivo";
            sha256 = "sha256-yH3eA5jgBwxqnpFQkg91KQMkQps5iM1v783KQkQcWUU=";
            version = "0.2.0";
          }
          {
            name = "templ";
            publisher = "a-h";
            sha256 = "sha256-WIBJorljcnoPUrQCo1eyFb6vQ5lcxV0i+QJlJdzZYE0=";
            version = "0.0.35";
          }
          {
            name = "ty";
            publisher = "astral-sh";
            sha256 = "sha256-Nps/ZsH8n0HZmf63SFUh7oGuvOz7PVu08maZzmU/2eg=";
            version = "2025.21.11682058";
          }
          {
            name = "vscode-containers";
            publisher = "ms-azuretools";
            sha256 = "sha256-MAeE99XmjIjYbr72UymnkrDKsNRSjNiB1jdffKTosHQ=";
            version = "2.0.3";
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
            sha256 = "sha256-qaa9qS87z4z27AN6dW/6rAnZfJPszFfBYLbaDXgDjlo=";
            version = "1.5.0";
          }
          {
            name = "vscode-thunder-client";
            publisher = "rangav";
            sha256 = "sha256-imClO22XcLA50rR7WXLiRsdXDF2gleS7iMUDlSFyDP4=";
            version = "2.35.2";
          }
          ]);
        userSettings = {
          "accessibility.dimUnfocused.enabled" = true;
          "breadcrumbs.enabled" = true;
          "diffEditor.codeLens" = true;
          "diffEditor.diffAlgorithm" = "advanced";
          "diffEditor.experimental.showcoloves" = true;
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
          "code-runner.enableAppInsights" = false;

          #####  Copilot #####
          # "github.copilot.chat.temporalContext.enabled" = true;
          "github.copilot.chat.completionContext.typescript.mode" = "on";
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
                "command" = [ "nixfmt" ];
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
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
            "editor.formatOnSave" = true;
          };

          ##### Redhat #####
          "redhat.telemetry.enabled" = false;

          ##### Ruff #####
          "ruff.enable" = true;
          "ruff.importStrategy" = "fromEnvironment";
          "ruff.lineLength" = 88;
          "ruff.organizeImports" = true;
          "ruff.fixAll" = true;
          "ruff.configurationPreference" = "filesystemFirst";
          "ruff.nativeServer" = "auto";

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
          "python.venvFolders" = [ ".venv"];
          "pythonIndent.trimLinesWithOnlyWhitespace" = true;

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
          "vs-kubernetes" = {
            "vs-kubernetes.crd-code-completion" = "enabled";
          };
          "vscode-kubernetes.log-viewer.autorun" = true;
          "vscode-kubernetes.log-viewer.destination" = "Terminal";
          "vscode-kubernetes.log-viewer.follow" = true;
          "vscode-kubernetes.log-viewer.timestamp" = true;
          "vsdocker.imageUser" = "docker.io/ryanwclark";

          ##### Snyk #####
          "snyk.advanced.cliPath" = "${config.home.homeDirectory}/.local/share/snyk/vscode-cli/snyk-linux";
          "snyk.folderConfigs" = [
            {
              "folderPath" = "${config.home.homeDirectory}/nixos-config";
              "baseBranch" = "main";
              "localBranches" = [
                "main"
                "develop"
              ];
            }
          ];

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
