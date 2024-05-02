{
  pkgs,
  ...
}:

{
  # nixpkgs.overlays = [
  #   (
  #     final: prev: {
  #       vscode = prev.vscode.overrideAttrs (_: rec {
  #         version = "1.87.0";
  #         plat = "linux-x64";
  #         archive_fmt = "tar.gz";
  #         pname = "vscode";
  #         src = prev.fetchurl {
  #           url = "https://update.code.visualstudio.com/${version}/${plat}/stable";
  #           sha256 = "00izdy01d34czxfjn6rv4vg179r7f264bls5fib4caakj9bblalw";
  #           name = "VSCode_${version}_${plat}.${archive_fmt}";
  #         };
  #       });
  #     }
  #   )
  # ];

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
        formulahendry.code-runner
        griimick.vhs
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "nord-deep";
          publisher = "marlosirapuan";
          version = "0.1.625";
          sha256 = "sha256-CJTku9MOet3JvVYLTQDgjKvmsU9V/NP2hamIFUfElMA=";
        }
        {
          name = "vscode-speech";
          publisher = "ms-vscode";
          version = "0.8.0";
          sha256 = "sha256-wOktHr0Dpw5KkQF861xBj0L/4ap8dc56l4mN2zhcQ4A=";
        }
        {
          name = "templ";
          publisher = "a-h";
          version = "0.0.24";
          sha256 = "sha256-D2XGCP57gsj02WOpoLR6pTtu2/GQejwQkevQdqHsh14=";
        }
        {
          name = "htmx-attributes";
          publisher = "craigrbroughton";
          version = "0.7.0";
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
          version = "2024.20.0";
          sha256 = "sha256-CqLmL8o+arki7UGWtZ/B6GQclWumLqgUqcPIXhG+Ays=";
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
          version = "0.5.2024031109";
          sha256 = "sha256-772l0EnAWXLg53TxPZf93js/W49uozwdslmzNwD1vIk=";
        }
        {
          name = "vscode-jsonnet";
          publisher = "grafana";
          version = "0.6.1";
          sha256 ="sha256-8t/9EJs9Ly6C89jM6HdCbeAdIvjSfePKD2WQwBtuJI0=";
        }
        # {
        #   name = "vscode-terraform";
        #   publisher = "hashicorp";
        #   version = "2.29.5";
        #   sha256 = "";
        # }
      ];

      userSettings = {
        "accessibilitySupport.voice.keywordActivation" = "chatInView";
        "accessibility.dimUnfocused.enabled" = true;
        # "audioCues.chatRequestSent" = "auto";
        "breadcrumbs.enabled" = true;
        "editor.accessibilityPageSize" = 500;
        "editor.fontLigatures" = false;
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

        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.defaultProfile.linux" = "bash";
        "terminal.integrated.fontSize" = 12;
        "terminal.integrated.mouseWheelZoom" = true;
        "terminal.integrated.enableImages" = true;
        "terminal.integrated.customGlyphs" = true;

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
        "yaml.maxComputedItems" = 1000;
      };
    };
  };
}
