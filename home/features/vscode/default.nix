{
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
        github.copilot-chat
        github.copilot
        github.codespaces
        github.github-vscode-theme
        github.vscode-github-actions
        github.vscode-pull-request-github
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        # ms-python.python
        ms-python.vscode-pylance
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.hexeditor
        ms-vscode.makefile-tools
        bradlc.vscode-tailwindcss
        charliermarsh.ruff
        dbaeumer.vscode-eslint
        donjayamanne.githistory
        esbenp.prettier-vscode
        formulahendry.code-runner
        golang.go
        griimick.vhs
        hediet.vscode-drawio
        jdinhlife.gruvbox
        jnoortheen.nix-ide
        jock.svg
        mikestead.dotenv
        njpwerner.autodocstring
        pkief.material-icon-theme
        redhat.vscode-xml
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
        vscodevim.vim
        wholroyd.jinja # Prefer Better Jinja
        yzhang.markdown-all-in-one
        gencer.html-slim-scss-css-class-completion
        catppuccin.catppuccin-vsc
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # {
        #   name = "ms-python";
        #   publisher = "ms-python";
        #   version = "2024.14.1";
        #   sha256 = "";
        # }

        {
          name = "yuck";
          publisher = "eww-yuck";
          version = "0.0.3";
          sha256 = "sha256-DITgLedaO0Ifrttu+ZXkiaVA7Ua5RXc4jXQHPYLqrcM=";
        }
        {
          name = "nord-deep";
          publisher = "marlosirapuan";
          version = "0.1.625";
          sha256 = "sha256-5QJ1zq5vc9PdJHTtpczR/Jf6aqi8qOx/6yUru4TLiQc=";
        }
        {
          name = "vscode-speech";
          publisher = "ms-vscode";
          version = "0.10.0";
          sha256 = "sha256-ef5uzpXVS92snyM47PwTcAhCKKwfn4iQFvZxMev4X58=";
        }
        {
          name = "templ";
          publisher = "a-h";
          version = "0.0.29";
          sha256 = "sha256-RZ++wxL2OqBh3hiLAwKIw5QLjU/imsK7irQUHbJ/tqM=";
        }
        {
          name = "htmx-attributes";
          publisher = "craigrbroughton";
          version = "0.8.0";
          sha256 = "sha256-TsemPZkq2Z13/vahRaP7z206BJaCZ1TR6OVv6aeDvyk=";
        }
        {
          name = "alpine-js-intellisense";
          publisher = "adrianwilczynski";
          version = "1.2.0";
          sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
        }
        # {
        #   name = "ruff";
        #   publisher = "charliermarsh";
        #   version = "2024.20.0";
        #   sha256 = "sha256-CqLmL8o+arki7UGWtZ/B6GQclWumLqgUqcPIXhG+Ays=";
        # }
        # {
        #   name = "remote-containers";
        #   publisher = "ms-vscode-remote";
        #   version = "0.386.0";
        #   sha256 = "sha256-qGDLpEHQBB1x++KD+xrcJTs8oGmZJXjsUojfG3TwczI=";
        # }
        # {
        #   name = "remote-ssh";
        #   publisher = "ms-vscode-remote";
        #   version = "0.113.2024072315";
        #   sha256 = "sha256-s+md+gM5V0EL17LwpiIa3Kbm/AOdYQP0PfOHtnLPYh8=";
        # }
        # {
        #   name = "remote-ssh-edit";
        #   publisher = "ms-vscode-remote";
        #   version = "0.86.0";
        #   sha256 = "sha256-JsbaoIekUo2nKCu+fNbGlh5d1Tt/QJGUuXUGP04TsDI=";
        # }
        {
          name = "remote-explorer";
          publisher = "ms-vscode";
          version = "0.5.2024070409";
          sha256 = "sha256-YwmsZii8TvBhloNQi6mezusEf/SmIq3i1ZNyKN5j1sU=";
        }
        {
          name = "vscode-jsonnet";
          publisher = "grafana";
          version = "0.6.1";
          sha256 ="sha256-8t/9EJs9Ly6C89jM6HdCbeAdIvjSfePKD2WQwBtuJI0=";
        }
        {
          name = "vscode-gitops-tools";
          publisher = "weaveworks";
          version = "0.27.0";
          sha256 = "sha256-7MCKDnHCot/CL/SqZ2WuTxbqFdF75EC5WC+OxW0dcaE=";
        }
        # {
        #   name = "vscode-terraform";
        #   publisher = "hashicorp";
        #   version = "2.29.5";
        #   sha256 = "";
        # }
        {
          name = "tailwind-color-matcher";
          publisher = "OmriGrossman";
          version = "1.0.8";
          sha256 = "sha256-WfFg1h5tY43W9YqgXkHDlxjRquFupuvLBwotTw0XoNk=";
        }
        {
          name = "sqlite-viewer";
          publisher = "qwtel";
          version = "0.6.4";
          sha256 = "sha256-wDSWQ36j6zMUD43PqP+x9VRxgDJJexFpxMyuHpbCi2s=";
        }
        {
          name = "yuck";
          publisher = "eww-yuck";
          version = "0.0.3";
          sha256 = "sha256-DITgLedaO0Ifrttu+ZXkiaVA7Ua5RXc4jXQHPYLqrcM=";
        }
      ];

      userSettings = {
        "accessibility.dimUnfocused.enabled" = true;
        "breadcrumbs.enabled" = true;

        "diffEditor.codeLens" = true;

        "editor.accessibilityPageSize" = 500;
        # "editor.fontFamily" = "JetBrains Mono, Fira Code, Menlo, Monaco, 'Courier New', monospace";
        "editor.fontLigatures" = true;
        # "editor.fontSize" = 12;
        # "editor.fontVariations" = true;
        # "editor.fontWeight" = "normal";
        "editor.formatOnPaste" = true;
        "editor.formatOnSave" = true;
        "editor.formatOnType" = true;
        "editor.inlineSuggest.enabled" = true;
        "editor.minimap.enabled" = false;
        "editor.parameterHints.enabled" = true;
        "editor.quickSuggestionsDelay" = 3;
        "editor.renderWhitespace" = "all";
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
        };
        "emmet.triggerExpansionOnTab" = true;

        "extensions.autoUpdate" = false;
        "files.associations" = {
          "*.css" = "tailwindcss";
        };
        "files.exclude" = { "**/node_modules/**" = true; };
        "files.autoSave" = "afterDelay";
        "files.trimTrailingWhitespace" = true;

        "telemetry.telemetryLevel" = "off";

        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "terminal.integrated.fontSize" = 12;
        "terminal.integrated.mouseWheelZoom" = true;
        "terminal.integrated.enableImages" = true;
        "terminal.integrated.customGlyphs" = true;
        "terminal.integrated.environmentChangesIndicator" = "off";

        # Nix IDE
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        # "nix.serverSettings".nil = {
        #   formatting.command = [ "nix" "fmt" "--" "-" ];
        #   nix.flake = {
        #     autoArchive = false;
        #     autoEvalInputs = false;
        #     nixpkgsInputName = null;
        #   };
        # };
        "redhat.telemetry.enabled" = false;

        # Even Better TOML
        "evenBetterToml.taplo.bundled" = false;
        "evenBetterToml.taplo.path" = "${pkgs.taplo}/bin/taplo";

        # Go
        "go.alternateTools" = {
          "gopls" = "${pkgs.gopls}/bin/gopls";
          "dlv" = "${pkgs.delve}/bin/dlv";
        };
        "gopls" = {
          "formatting.gofumpt" = true;
          "ui.diagnostic.staticcheck" = true;
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
        };
        "tailwindCSS.codeActions" = true;
        "tailwindCSS.colorDecorators" = true;
        "tailwindCSS.emmetCompletions" = true;
        "tailwindCSS.hovers" = true;
        "tailwindCSS.showPixelEquivalents" = true;
        "tailwindCSS.suggestions" = true;
        "tailwindCSS.validate" = true;

        "window.zoomLevel" = 1;
        "workbench.editor.enablePreview" = true;
        "workbench.colorTheme" = "Catppuccin Frappé";

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
}
