 {
  config,
  pkgs,
  lib,
  ...
}:

with lib; {
  options.vscode.enable = mkEnableOption "vscode settings";

  config = mkIf config.vscode.enable {
    # if use vscode in wayland, uncomment this line
    # environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

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
        golang.go
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

        # vscode-icons-team.vscode-icons
      ];

      mutableExtensionsDir = false;

      userSettings = {

        editor = {
          "fontSize" = 12;
          "fontFamily" = "JetBrainsMono Nerd Font";
          "renderWhitespace" = "all";
          "useTabStops" = false;
          "formatOnSave" = false;
          "fontLigatures" = true;
          "lineHeight" = 20;
          "rulers" = [ 80 120 ];
          "tabSize" = 2;
          "suggestSelection" = "first";
          "inlineSuggest.enabled" = true;
          "minimap.enabled" = false;
        };

        "files.exclude" = { "**/node_modules/**" = true; };
        "files.autoSave" = "afterDelay";
        "files.trimTrailingWhitespace" = true;
        "telemetry.telemtryLevel" = "off";
        "breadcrumbs.enabled" = true;
        "workbench.fontAliasing" = "antialiased";
        "workbench.editor.enablePreview" = false;
        "workbench.colorTheme" = "Default Dark Modern";

        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";

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
        "vscode-kubernetes.helm-path" = "etc/profiles/per-user/administrator/bin/helm";
        "vscode-kubernetes.kubectl-path" = "etc/profiles/per-user/administrator/bin/kubectl";
        "vscode-kubernetes.minikube-path" = "etc/profiles/per-user/administrator/bin/minikube";
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
