{
  config,
  pkgs,
  ...
}:


{
  imports = [ ./custom.theme/themes/theme.json.nix ];

  home.file.".config/vscode/plugins/custom.theme/package.json" = {
    source = ./custom.theme/package.json;
  };

  home.packages = with pkgs; [
    tailwindcss
    fluxctl
    taplo # Even Better TOML
    nvfetcher
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;

    profiles = {
      default = {
        enableExtensionUpdateCheck = true;
        enableUpdateCheck = false;
        extensions = let
          themeExtension = pkgs.runCommandLocal "custom-vscode"
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
          ] ++
          (with pkgs.vscode-extensions; [
            aaron-bond.better-comments
            bierner.markdown-mermaid
            bradlc.vscode-tailwindcss
            charliermarsh.ruff
            christian-kohler.path-intellisense
            dbaeumer.vscode-eslint
            donjayamanne.githistory
            esbenp.prettier-vscode
            formulahendry.code-runner
            github.codespaces
            github.copilot
            github.copilot-chat
            github.vscode-github-actions
            github.vscode-pull-request-github
            golang.go
            griimick.vhs
            hediet.vscode-drawio
            jetmartin.bats
            jnoortheen.nix-ide
            jock.svg
            marp-team.marp-vscode
            mikestead.dotenv
            ms-azuretools.vscode-docker
            ms-kubernetes-tools.vscode-kubernetes-tools
            ms-python.debugpy
            ms-python.python
            ms-python.vscode-pylance
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.hexeditor
            ms-vscode.live-server
            njpwerner.autodocstring
            quicktype.quicktype
            redhat.vscode-xml
            redhat.vscode-yaml
            samuelcolvin.jinjahtml
            shyykoserhiy.vscode-spotify
            tailscale.vscode-tailscale
            tamasfe.even-better-toml
            usernamehw.errorlens
            # vue.volar
            yzhang.markdown-all-in-one
          ]) ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
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
              sha256 = "sha256-Z6i2zal3uhzdG1nBZsp5/fOqki5Soo7JDkfunnx/FVo=";
              version = "2025.1.10511014";
            }
            {
              name = "prom";
              publisher = "ventura";
              sha256 = "sha256-h8pRrPzmu8+5ZiOLALjackr4zWuFAqi1ex7Gp2iOZKk=";
              version = "1.3.3";
            }
            {
              name = "remote-explorer";
              publisher = "ms-vscode";
              sha256 = "sha256-tCNkC7qa59oL9TXA+OKN0Tq5wl0TOLJhHpiKRLmMlgo=";
              version = "0.5.2025021709";
            }
            {
              name = "remotehub";
              publisher = "github";
              sha256 = "sha256-Xb28yff0tiQDUuwC5Mv0rwXqLgZOU4B3KZAht78NfFU=";
              version = "0.65.2024112101";
            }
            {
              name = "tailwind-color-matcher";
              publisher = "OmriGrossman";
              sha256 = "sha256-WfFg1h5tY43W9YqgXkHDlxjRquFupuvLBwotTw0XoNk=";
              version = "1.0.8";
            }
            {
              name = "tailwind-docs";
              publisher = "austenc";
              sha256 = "sha256-EB3ggxo2NqiH8yVpsNzDRb+fvsd6Qd5aXRM6FoZn5k8=";
              version = "2.1.0";
            }
            {
              name = "templ";
              publisher = "a-h";
              sha256 = "sha256-RZ++wxL2OqBh3hiLAwKIw5QLjU/imsK7irQUHbJ/tqM=";
              version = "0.0.29";
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
              name = "vscode-thunder-client";
              publisher = "rangav";
              sha256 = "sha256-bsbSYNs2+X8JIv3t3S9ftlCUe60gktpQwzhg9Yzgy5o=";
              version = "2.34.2";
            }
            {
              name = "rasi";
              publisher = "dlasagno";
              version = "1.0.0";
              sha256 = "sha256-s60alej3cNAbSJxsRlIRE2Qha6oAsmcOBbWoqp+w6fk=";
            }
            {
              name = "hadolint";
              publisher = "exiasr";
              version = "1.1.2";
              sha256 = "sha256-6GO1f8SP4CE8yYl87/tm60FdGHqHsJA4c2B6UKVdpgM=";
            }
            {
              name = "vsc-python-indent";
              publisher = "kevinrose";
              version = "1.21.0";
              sha256 = "sha256-SvJhVG8sofzV0PebZG4IIORX3AcfmErDQ00tRF9fk/4=";
            }
            {
              name = "explorer";
              publisher = "vitest";
              version = "1.14.3";
              sha256 = "sha256-L/VpdB1pTt5O+84I7vShEfoKAi+S7PGDhYhpYmRUfX8=";
            }
            {
              name = "biome";
              publisher = "biomejs";
              version = "2025.2.72227";
              sha256 = "sha256-Lj5+Vy8IbU70y6ee42cjxyz/mwpIAhWSF4KtL9OYo2Q=";
            }
            {
              name = "playwright";
              publisher = "ms-playwright";
              version = "1.1.13";
              sha256 = "sha256-gSIWwD8WHKMM5wpuPpSKpBB+oxaqO2vO8wHTN43jmrM=";
            }
            {
              name = "ty";
              publisher = "astral-sh";
              version = "2025.3.11272138";
              sha256 = "sha256-Lgm+rwBmUJEmWKGOuuxXbyGHGKoOie8a3RDK9ez0+4E=";
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
          "terminal.integrated.fontFamily" = "UbuntuMono Nerd Font";
          "terminal.integrated.minimumContrastRatio" = 1;
          "terminal.integrated.mouseWheelZoom" = true;
          "terminal.integrated.scrollback" = 10000;
          "window.newWindowProfile" = "Default";
          "window.titleBarStyle" = "custom";
          "window.zoomLevel" = 2;
          "workbench.colorTheme" = "Custom Theme";
          "workbench.editor.enablePreview" = true;
          "workbench.externalBrowser" = "chrome";

          "remote.defaultExtensionsIfInstalledLocally" = [
            "GitHub.copilot"
            "GitHub.copilot-chat"
            "GitHub.vscode-pull-request-github"
          ];

          #############################
          #    Extension Settings     #
          #############################

          ##### Autodoc Strings #####
          "autodocstring.docstringFormat" = "google";
          "autoDocstring.generateDocstringOnEnter" = true;
          "autoDocstring.guessTypes" = true;
          "autoDocstring.startOnNewLine" = true;


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
          "github.copilot.editor.enableAutoCompletions" = true;
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
          "dev.containers.defaultExtensionsIfInstalledLocally" = [
            "GitHub.copilot"
            "GitHub.copilot-chat"
            "GitHub.vscode-pull-request-github"
          ];
          "dotfiles.repository" = "https://github.com/ryanwclark1/dotfiles.git";
          "dotfiles.installCommand" = "bootstrap.sh";

          ##### Docker #####
          "docker.composeCommand" = "docker compose";
          "docker.contexts.showInStatusBar" = true;

          ##### Nix IDE #####
          "nix.enableLanguageServer" = true;

          ##### Redhat #####
          "redhat.telemetry.enabled" = false;

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
          "go.lintOnSave" = "golangci-lint";
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
            "ui.completion.matcher" = "fuzzy";
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

          ##### Python #####
          "python.testing.autoTestDiscoverOnSaveEnabled" = false;
          "python.testing.pytestEnabled" = true;
          "python.testing.pytestArgs" = [
            "tests"
          ];
          "python.testing.unittestEnabled" = false;

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
            "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
            "editor.formatOnSave" = true;
          };

          "[github-actions-workflow]" = {
            "editor.autoIndent" = "advanced";
            "editor.defaultFormatter" = "redhat.vscode-yaml";
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
            "editor.defaultFormatter" = "charliermarsh.ruff";
            "editor.formatOnSave" = true;
            "editor.tabSize" = 4;
          };
          "[toml]" = {
            "editor.defaultFormatter" = "tamasfe.even-better-toml";
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 4;
          };
          "[yaml]" = {
            "editor.autoIndent" = "advanced";
            "editor.defaultFormatter" = "redhat.vscode-yaml";
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
          };


          ##### Typescript #####
          "[typescriptreact]"."editor.defaultFormatter" = "vscode.typescript-language-features";

          ##### Git #####
          "git.autofetch" = true;
          "git.autofetchPeriod" = 30;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;

          ##### Github #####
          "github.codespaces.defaultExtensions" = [
            "GitHub.codespaces"
            "GitHub.vscode-pull-request-github"
            "Github.copilot-chat"
            "Github.copilot"
          ];

          ##### Kubernetes #####
          "vs-kubernetes" = {
            "vs-kubernetes.crd-code-completion" = "enabled";
          };
          "vscode-kubernetes.log-viewer.autorun" = true;
          "vscode-kubernetes.log-viewer.destination" = "Terminal";
          "vscode-kubernetes.log-viewer.follow" = true;
          "vscode-kubernetes.log-viewer.timestamp" = true;
          "vsdocker.imageUser" = "docker.io/ryanwclark";

          ##### CSS #####
          "[css]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

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
