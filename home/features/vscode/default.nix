{
  pkgs,
  ...
}:

{

  home.packages = with pkgs; [
    tailwindcss
  ];

  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode;
      mutableExtensionsDir = false;
      enableExtensionUpdateCheck = false;
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
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.hexeditor
        ms-vscode.makefile-tools

        bradlc.vscode-tailwindcss
        dbaeumer.vscode-eslint
        donjayamanne.githistory
        golang.go
        jdinhlife.gruvbox
        jnoortheen.nix-ide
        jock.svg
        esbenp.prettier-vscode
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
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "nord-deep";
          publisher = "marlosirapuan";
          version = "0.1.624";
          sha256 = "sha256-CJTku9MOet3JvVYLTQDgjKvmsU9V/NP2hamIFUfElMA=";
        }
        {
          name = "vscode-speech";
          publisher = "ms-vscode";
          version = "0.6.0";
          sha256 = "sha256-wOktHr0Dpw5KkQF861xBj0L/4ap8dc56l4mN2zhcQ4A=";
        }
        {
          name = "templ";
          publisher = "a-h";
          version = "0.0.22";
          sha256 = "sha256-VKzB7QC1eFPYAL66V3gNoQ+9Djz8veyMLlNMbVNiqqw=";
        }
        {
          name = "htmx-attributes";
          publisher = "craigrbroughton";
          version = "0.6.0";
          sha256 = "sha256-ly8jBv2s/BSoze36krut3OJGGfr8J2RMKfjnN7hWeTY=";
        }
        {
          name = "alpine-js-intellisense";
          publisher = "adrianwilczynski";
          version = "1.2.0";
          sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
        }
        {
          name = "ruff";
          publisher = "charliermarsh";
          version = "2024.14.0";
          sha256 = "sha256-JuOn9vQibr9emyKWL9/5QKsZDKAbwdbu+hvsl+fteTc=";
        }
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.86.0";
          sha256 = "sha256-JsbaoIekUo2nKCu+fNbGlh5d1Tt/QJGUuXUGP04TsDI=";
        }
        {
          name = "remote-explorer";
          publisher = "ms-vscode";
          version = "0.4.3";
          sha256 = "sha256-772l0EnAWXLg53TxPZf93js/W49uozwdslmzNwD1vIk=";
        }
      ];

      userSettings = {
        "accessibilitySupport.voice.keywordActivation" = "chatInView";
        "accessibility.dimUnfocused.enabled" = true;
        "audioCues.chatRequestSent" = "auto";
        "breadcrumbs.enabled" = true;
        "editor.accessibilityPageSize" = 500;
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 12;
        "editor.fontVariations" = true;
        "editor.fontWeight" = "normal";
        # "editor.formatOnSave" = true;
        "editor.inlineSuggest.enabled" = true;
        "editor.minimap.enabled" = false;
        "editor.parameterHints.enabled" = true;
        "editor.quickSuggestions" = {
          "other" = true;
          "comments" = true;
          "strings" = true;
        };
        "editor.renderWhitespace" = "all";
        "editor.rulers" = [
          80
          120
        ];

        "editor.suggest.showStatusBar" = true;
        "editor.suggest.localityBonus" = true;
        "editor.suggestSelection" = "first";
        "editor.quickSuggestionsDelay" = 3;
        "editor.tabCompletion" = "on";
        "editor.tabSize" = 2;
        "editor.useTabStops" = true;
        "editor.wordBasedSuggestions" = "matchingDocuments";
        "editor.wordWrap" = "on";
        "editor.snippetSuggestions" = "top";
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
        "workbench.editor.enablePreview" = false;
        "workbench.colorTheme" = "Nord Deep";

        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "terminal.integrated.fontSize" = 12;
        "terminal.integrated.mouseWheelZoom" = true;

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

        "git.confirmSync" = false;
        "git.autofetch" = true;
        "git.enableSmartCommit" = true;
        "window.zoomLevel" = 1;
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
        # "tabby.usage.anonymousUsageTracking" = true; # this settings actually disables telemetry (pretty weird naming)
        # Configurations: https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss
        "tailwindCSS.includeLanguages" = {
          "plaintext" = "html";
        };
        "tailwindCSS.emmetCompletions" = true;
        "tailwindCSS.colorDecorators" = true;
        "tailwindCSS.showPixelEquivalents" = true;
        "tailwindCSS.hovers" = true;
        "tailwindCSS.suggestions" = true;
        "tailwindCSS.codeActions" = true;
        "tailwindCSS.validate" = true;


        "git.autofetchPeriod" = 30;
        "github.copilot.advanced" = {
          "listCount" = 3;
        };
        "diffEditor.codeLens" = true;
        "editor.formatOnPaste" = true;
        "editor.formatOnType" = true;
        "github.codespaces.defaultExtensions" = [
          "GitHub.codespaces"
          "GitHub.vscode-pull-request-github"
          "Github.copilot-chat"
          "Github.copilot"
        ];
      };
    };
  };
}
