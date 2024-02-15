 {
  pkgs,
  ...
}:

{
  # if use vscode in wayland, uncomment this line
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
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
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.hexeditor
        ms-vscode.makefile-tools
        ms-vscode.anycode
        golang.go
        wholroyd.jinja # Prefer Better Jinja
        # hash mismatch in nixos upgrade to unstable
        # charliermarsh.ruff
        ms-azuretools.vscode-docker
        bradlc.vscode-tailwindcss
        jnoortheen.nix-ide
        jock.svg
        mikestead.dotenv
        redhat.vscode-xml
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        tamasfe.even-better-toml

        esbenp.prettier-vscode
        yzhang.markdown-all-in-one
        donjayamanne.githistory

        pkief.material-icon-theme
        jdinhlife.gruvbox

        mikestead.dotenv
        dbaeumer.vscode-eslint
        # vscode-extension-dbaeumer-vscode-eslint

        # vscode-icons-team.vscode-icons
      ];

      userSettings = {

          "editor.fontLigatures" = true;
          "editor.fontVariations" = true;
          "editor.fontWeight" = "normal";
          "editor.fontFamily" = "JetBrainsMono Nerd Font";
          "editor.fontSize" = 12;
          "editor.formatOnSave" = true;
          "editor.inlineSuggest.enabled" = true;
          "editor.minimap.enabled" = false;
          "editor.renderWhitespace" = "all";
          "editor.rulers" = [
            80
            120
          ];
          "editor.suggestSelection" = "first";
          "editor.tabSize" = 2;
          "editor.wordWrap" = "on";
          "editor.useTabStops" = true;

        "files.exclude" = { "**/node_modules/**" = true; };
        "files.autoSave" = "afterDelay";
        "files.trimTrailingWhitespace" = true;
        "telemetry.telemetryLevel" = "off";
        "breadcrumbs.enabled" = true;
        "workbench.fontAliasing" = "antialiased";
        "workbench.editor.enablePreview" = false;
        "workbench.colorTheme" = "Default Dark Modern";

        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "terminal.integrated.copyOnSelection" = true;

        # Nix IDE
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        "nix.serverSettings".nil = {
          formatting.command = ["nix" "fmt" "--" "-"];
          nix.flake = {
            autoArchive = false;
            autoEvalInputs = false;
            nixpkgsInputName = null;
          };
        };
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
        "vscode-kubernetes.helm-path" = "${pkgs.kubernetes-helm}/bin/helm";
        "vscode-kubernetes.kubectl-path" = "${pkgs.kubectl}/bin/kubectl";
        "vscode-kubernetes.minikube-path" = "${pkgs.minikube}/bin/minikube";
        "vscode-kubernetes.log-viewer.autorun" = true;
        "vscode-kubernetes.log-viewer.destination" = "Terminal";
        "vscode-kubernetes.log-viewer.follow" = true;
        "vscode-kubernetes.log-viewer.timestamp" = true;
        "vsdocker.imageUser" = "docker.io/ryanwclark";
        # "nix.serverPath" = "nil";
        "tabby.usage.anonymousUsageTracking" = true; # this settings actually disables telemetry (pretty weird naming)
        "github.copilot.advanced" = {
          "listCount" = 3;
        };
      };
    };
  };
}
