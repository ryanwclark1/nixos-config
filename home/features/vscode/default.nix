{
  config,
  lib,
  pkgs,
  ...
}:


{
# Overlay for VSCode version

  home.packages = with pkgs; [
    tailwindcss
    fluxctl
  ];

  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode;
      mutableExtensionsDir = false;
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        github.codespaces
        github.copilot
        github.copilot-chat
        github.github-vscode-theme
        github.vscode-github-actions
        github.vscode-pull-request-github
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-vscode.cmake-tools
        ms-vscode.hexeditor
        ms-vscode.makefile-tools
        bradlc.vscode-tailwindcss
        catppuccin.catppuccin-vsc
        charliermarsh.ruff
        dbaeumer.vscode-eslint
        donjayamanne.githistory
        esbenp.prettier-vscode
        formulahendry.code-runner
        gencer.html-slim-scss-css-class-completion
        golang.go
        griimick.vhs
        hediet.vscode-drawio
        jdinhlife.gruvbox
        jnoortheen.nix-ide
        jock.svg
        mikestead.dotenv
        njpwerner.autodocstring
        pkief.material-icon-theme
        quicktype.quicktype
        redhat.vscode-xml
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        tailscale.vscode-tailscale
        tamasfe.even-better-toml
        vscodevim.vim
        wholroyd.jinja # Prefer Better Jinja
        yzhang.markdown-all-in-one
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "alpine-js-intellisense";
          publisher = "adrianwilczynski";
          version = "1.2.0";
          sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
        }
        {
          name = "ansible";
          publisher = "redhat";
          sha256 = "sha256-NDIGyVCo3Az6oncnKR9PXXnZ4ynwF7HBeIiNyiGTPko=";
          version = "24.10.0";
        }
        {
          name = "bun-vscode";
          publisher = "oven";
          sha256 = "sha256-9aoDDO7hh+YPTKh64z3rZhnTW5H8Se3+ZTncGrsKyJ0=";
          version = "0.0.15";
        }
        # {
        #   name = "copilot";
        #   publisher = "github";
        #   sha256 = "sha256-IJGNIPmCq96Xi9UfYrUoD5lKItnoWd1be5EYJv0ngXE=";
        #   version = "1.244.0";
        # }
        # {
        #   name = "copilot-chat";
        #   publisher = "github";
        #   sha256 = "sha256-nsdgpjPmHY3AmD/Hs55iCiwBaK0+X9g+f8tR0mrQxzA=";
        #   version = "0.21.0";
        # }
        {
          name = "htmx-attributes";
          publisher = "craigrbroughton";
          sha256 = "sha256-TsemPZkq2Z13/vahRaP7z206BJaCZ1TR6OVv6aeDvyk=";
          version = "0.8.0";
        }
        {
          name = "remote-explorer";
          publisher = "ms-vscode";
          sha256 = "sha256-U7P4GkjIk+WRAY1Ng5AMx2EiCwEsXY0Rt+b+4fBSJms=";
          version = "0.5.2024103109";
        }
        {
          name = "remotehub";
          publisher = "github";
          sha256 = "sha256-Nh4PxYVdgdDb8iwHHUbXwJ5ZbMruFB6juL4Yg/wdKMY=";
          version = "0.64.0";
        }
        {
          name = "sqlite-viewer";
          publisher = "qwtel";
          sha256 = "sha256-b7x28eme4v0gOP0hBFMXGG8NFQvIsTP7rRdWZJ04EnA=";
          version = "0.9.3";
        }
        {
          name = "sqltools";
          publisher = "mtxr";
          sha256 = "sha256-bTrHAhj8uwzRIImziKsOizZf8+k3t+VrkOeZrFx7SH8=";
          version = "0.28.3";
        }
        {
          name = "sqltools-driver-pg";
          publisher = "mtxr";
          sha256 = "sha256-XnPTMFNgMGT2tJe8WlmhMB3DluvMZx9Ee2w7xMCzLYM=";
          version = "0.5.4";
        }
        {
          name = "sqltools-driver-sqlite";
          publisher = "mtxr";
          sha256 = "sha256-wFgb6wDSgPbPtEVKbHcUeURqbVAqDsEEhFUcBhQtmF8=";
          version = "0.5.1";
        }
        {
          name = "tailwind-color-matcher";
          publisher = "OmriGrossman";
          sha256 = "sha256-WfFg1h5tY43W9YqgXkHDlxjRquFupuvLBwotTw0XoNk=";
          version = "1.0.8";
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
          name = "vscode-speech";
          publisher = "ms-vscode";
          sha256 = "sha256-fxmaPI7uq7DQlzgJc8RcZzHDOwMuodSCf9TkLU9+/+k=";
          version = "0.12.1";
        }
        {
          name = "vscode-thunder-client";
          publisher = "rangav";
          sha256 = "sha256-91zjmzovEu6HRZZUK38oENlWUKyQcxgDKLIAMDdi5WE=";
          version = "2.29.12";
        }
        {
          name = "yuck";
          publisher = "eww-yuck";
          sha256 = "sha256-DITgLedaO0Ifrttu+ZXkiaVA7Ua5RXc4jXQHPYLqrcM=";
          version = "0.0.3";
        }
      ];

      userSettings = {
        "accessibility.dimUnfocused.enabled" = true;
        "breadcrumbs.enabled" = true;

        "diffEditor.codeLens" = true;
        "diffEditor.experimental.showMoves" = true;
        "diffEditor.diffAlgorithm" = "advanced";
        "diffEditor.maxFileSize" = 0;
        "diffEditor.renderIndicators" = true;

        "editor.accessibilityPageSize" = 5000;
        "editor.experimental.treeSitterTelemetry" = false;
        "editor.fontLigatures" = true;
        "editor.foldingMaximumRegions" = 10000;
        "editor.foldingStrategy" = "auto";
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

        "emmet.showSuggestionsAsSnippets" = true;
        "emmet.includeLanguages" = {
          "javascript" = "javascriptreact";
          "typescript" = "typescriptreact";
          "vue-html" = "html";
          "templ" = "html";
        };
        "emmet.triggerExpansionOnTab" = true;

        "extensions.autoUpdate" = false;
        "files.associations" = {
          "*.css" = "tailwindcss";
        };
        "files.exclude" = {
          "**/node_modules/**" = true;
          "**/venv/**" = true;
        };
        "files.autoSave" = "afterDelay";
        "files.trimTrailingWhitespace" = true;
        "telemetry.telemetryLevel" = "off";
        # "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "terminal.integrated.fontSize" = 12;
        "terminal.integrated.minimumContrastRatio" = 1;
        "terminal.integrated.mouseWheelZoom" = true;
        "terminal.integrated.enableImages" = true;
        "terminal.integrated.customGlyphs" = true;
        "terminal.integrated.environmentChangesIndicator" = "off";
        "window.titleBarStyle" = "custom";
        "window.zoomLevel" = 1;
        "workbench.editor.enablePreview" = true;
        "workbench.externalBrowser" = "chrome";

        "html-css-class-completion.enableEmmetSupport" = true;
        "html-css-class-completion.enableFindUsage" = true;
        "html-css-class-completion.enableScssFindUsage" = true;

        # Code Runner
        "code-runner.enableAppInsights" = false;

        "github.copilot.editor.enableAutoCompletions" = true;
        "github.copilot.enable" = {
          "c" = true;
          "cpp" = true;
          "csharp" = true;
          "dockercompose" = true;
          "css" = true;
          "cuda-cpp" = true;
          "diff" = true;
          "dockerfile" = true;
          "erlang" = true;
          "fsharp" = true;
          "git-commit" = true;
          "git-rebase" = true;
          "go" = true;
          "groovy" = true;
          "handlebars" = true;
          "haml" = true;
          "haskell" = true;
          "html" = true;
          "ini" = true;
          "java" = true;
          "javascript" = true;
          "javascriptreact" = true;
          "json" = true;
          "jsonc" = true;
          "julia" = true;
          "latex" = true;
          "less" = true;
          "lua" = true;
          "makefile" = true;
          "markdown" = true;
          "objective-c" = true;
          "objective-cpp" = true;
          "ocaml" = true;
          "perl" = true;
          "php" = true;
          "plaintext" = true;
          "powershell" = true;
          "pug" = true;
          "python" = true;
          "r" = true;
          "ruby" = true;
          "rust" = true;
          "scss" = true;
          "sass" = true;
          "shellscript" = true;
          "slim" = true;
          "sql" = true;
          "stylus" = true;
          "svelte" = true;
          "swift" = true;
          "typescript" = true;
          "typescriptreact" = true;
          "tex" = true;
          "vue" = true;
          "vue-html" = true;
          "xml" = true;
          "xsl" = true;
          "yaml" = true;
        };

        "github.copilot.chat.startDebugging.enabled" = true;
        "github.copilot.chat.experimental.generateTests.codeLens" = true;
        "github.copilot.chat.experimental.inlineChatCompletionTrigger.enabled" = true;
        "github.copilot.chat.experimental.startDebugging.enabled" = true;
        "github.copilot.chat.experimental.temporalContext.enabled" = true;
        "github.copilot.chat.localeOverride" = "en";
        "github.copilot.chat.runCommand.enabled" = true;
        "github.copilot.chat.useProjectTemplates" = true;
        "github.copilot.chat.welcomeMessage" = "never";
        "github.copilot.editor.enableCodeActions" = true;
        "github.copilot.renameSuggestions.triggerAutomatically" = true;

        # Dev Containers
        # "dev.containers.dockerComposePath" = "${pkgs.docker}/bin/docker compose";
        # "dev.containers.dockerPath" = "${pkgs.docker}/bin/docker";
        "dev.containers.defaultExtensionsIfInstalledLocally" = [
          "GitHub.copilot"
          "GitHub.copilot-chat"
          "GitHub.vscode-pull-request-github"
        ];
        "dotfiles.repository" = "https://github.com/ryanwclark1/dotfiles.git";

        # Docker
        "docker.composeCommand" = "docker compose";
        "docker.contexts.showInStatusBar" = true;
        # "docker.dockerPath" = "${pkgs.docker}/bin/docker";

        # Draw.io
        "hediet.vscode-drawio.plugins" = [
          "number"
          "sql"
        ];

        # Nix IDE
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";

        # Redhat
        "redhat.telemetry.enabled" = false;

        # Even Better TOML
        "evenBetterToml.taplo.bundled" = false;
        "evenBetterToml.taplo.path" = "${pkgs.taplo}/bin/taplo";

        # Go
        "go.alternateTools" = {
          "dlv" = "${pkgs.delve}/bin/dlv";
          "dlv-dap" = "${pkgs.delve}/bin/dlv-dap";
          "gopls" = "${pkgs.gopls}/bin/gopls";
          "go" = "${lib.getExe config.programs.go.package}";
          "gofumpt" = "${pkgs.gofumpt}/bin/gofumpt";
          "golangci-lint" = "${pkgs.golangci-lint}/bin/golangci-lint";
          "gotestsum" = "${pkgs.gotestsum}/bin/gotestsum";
          "staticcheck" = "${pkgs.go-tools}/bin/staticcheck";
          "templ" = "${pkgs.templ}/bin/templ";
        };
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
        "go.gopath" = "${config.home.homeDirectory}/go";
        "go.goroot" = "${lib.getExe config.programs.go.package}";
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

        # JSON
        "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";

        # Git
        "git.autofetch" = true;
        "git.autofetchPeriod" = 30;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        #Github
        "github.codespaces.defaultExtensions" = [
          "GitHub.codespaces"
          "GitHub.vscode-pull-request-github"
          "Github.copilot-chat"
          "Github.copilot"
        ];
        "github.copilot.advanced" = {
          "listCount" = 3;
        };

        # Kubernetes
        "vs-kubernetes" = {
          "vs-kubernetes.crd-code-completion" = "enabled";
        };
        "vscode-kubernetes.helm-path.linux" = "${pkgs.kubernetes-helm}/bin/helm";
        "vscode-kubernetes.kubectl-path.linux" = "${pkgs.kubectl}/bin/kubectl";
        "vscode-kubernetes.minikube-path.linux" = "${pkgs.minikube}/bin/minikube";
        "vscode-kubernetes.log-viewer.autorun" = true;
        "vscode-kubernetes.log-viewer.destination" = "Terminal";
        "vscode-kubernetes.log-viewer.follow" = true;
        "vscode-kubernetes.log-viewer.timestamp" = true;
        "vsdocker.imageUser" = "docker.io/ryanwclark";

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

        # Templ
        "templ.pprof" = true;
        "templ.goplsRPCTrace" = true;


        # YAML
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
        "[templ]" = {
          "editor.defaultFormatter" = "a-h.templ";
        };
      };
    };
  };
}
