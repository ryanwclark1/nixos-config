{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.tmux = {
    enable = mkEnableOption "tmux";
    autorun = mkEnableOption "autorun tmux";
    shell = mkOption {
      type = types.str;
      default = config.shell.user;
    };
  };

  config = mkIf config.tmux.enable {
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      historyLimit = 10000;
      escapeTime = 0;
      mouse = true;
      shell = config.tmux.shell;
      sensibleOnTop = true;
      keyMode = "vi";
      prefix = "C-Space";
      extraConfig = let
        nextToggle = ''bind-key  -n C-\\ next-window'';
        newWindow = ''bind-key  -n C-n next-window'';
        killSession2 = ''bind-key   C-k kill-session'';
        killSession = ''bind-key -n  C-k kill-session'';
        horPane = ''bind | split-window -h -c "#{pane_current_path}"'';
        verPane = ''bind - split-window -v -c "#{pane_current_path}"'';
        newWin = ''bind c new-window -c "#{pane_current_path}"'';
        newPrefix = ''bind C-Space send-prefix'';
        willowBinding = ''bind -n M-w new-session -A -s willow "smug willow -a"'';
      in
        builtins.concatStringsSep "\n" [nextToggle horPane verPane newWin newWindow killSession2 killSession newPrefix willowBinding];

      plugins = with pkgs; [
        tmuxPlugins.open
        {
          plugin = tmuxPlugins.tmux-fzf;
          extraConfig = ''TMUX_FZF_LAUNCH_KEY="C-f"'';
        }
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = "set -g @catppuccin_flavour 'macchiato'\n" + "set -g @catppuccin_window_tabs_enabled on" + "\n" + "set -g @catppuccin_window_right_separator \"█ \"" + "\n" + "set -g @catppuccin_status_left_separator \"█\"" + "\n" + "set -g @catppuccin_status_right_separator \"█\"" + "\n";
        }
        {
          plugin = tmuxPlugins.yank;
          extraConfig = let
            beginSelection = "bind-key -T copy-mode-vi v send-keys -X begin-selection";
            rectangleToggle = "bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle";
            copySelectionAndCancel = "bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel";
          in
            builtins.concatStringsSep "\n" [beginSelection rectangleToggle copySelectionAndCancel];
        }
        tmuxPlugins.tmux-thumbs
      ];
    };

    home.packages = with pkgs; [
      smug
      tmux-sessionizer
      twm
    ];

    home.file = let
      codeWindow = {commandPrefix ? []}: {
        name = " code";
        commands = commandPrefix ++ ["hx ."];
        layout = "main-horizontal";
      };

      terminalWindow = {commandPrefix ? []}: {
        name = "  terminal";
        commands =
          commandPrefix
          ++ [
            "git status"
            "ls"
          ];
      };
      fileManagerWindow = {
        name = " files";
        commands = ["lf"];
      };

      goLogsWindow = {
        name = " logs";
        commands = [
          "nix-shell -p clang golangci-lint hwatch"
          # "hwatch -c -n 10  go build"
        ];
        panes = [
          {
            commands = [
              "nix-shell -p clang golangci-lint hwatch"
              # "hwatch -c -n 10 golangci-lint run"
            ];
          }
        ];
      };

      cargoLogWindow = {
        name = " logs";
        commands = [
          "cargo update"
          "cargo fetch"
          "cargo test"
          "cargo clippy --workspace --all-targets --all-features"
          "cargo watch --exec  \"clippy --workspace --all-targets --all-features\""
        ];
      };

      zolaServeWindow = {
        name = " serving";
        commands = ["zola serve"];
      };
    in {
      "soapberry.yml" = with lib; {
        target = ".config/smug/soapberry.yml";
        text =
          generators.toYAML {}
          {
            session = "soapberry ";
            root = "~/kapa/pro/soapberry";
            windows = [
              (codeWindow {})
              (terminalWindow {})
              fileManagerWindow
              cargoLogWindow
            ];
          };
      };

      "aero-core.yml" = with lib; {
        target = ".config/smug/aero-core.yml";
        text =
          generators.toYAML {}
          {
            session = "aero-core ";
            root = "~/kapa/pro/asanbilit/asanbilit-core/src";
            windows = [
              (codeWindow {commandPrefix = ["nix-shell -p clang golangci-lint"];})
              (terminalWindow {commandPrefix = ["nix-shell -p clang golangci-lint"];})
              fileManagerWindow
              goLogsWindow
            ];
          };
      };

      "aero-unified.yml" = with lib; {
        target = ".config/smug/aero-unified.yml";
        text =
          generators.toYAML {}
          {
            session = "aero-unified ";
            root = "~/kapa/pro/asanbilit/unified-aero/src";
            windows = [
              (codeWindow {commandPrefix = ["nix-shell -p clang golangci-lint"];})
              (terminalWindow {commandPrefix = ["nix-shell -p clang golangci-lint"];})
              fileManagerWindow
              goLogsWindow
            ];
          };
      };

      "willow.yml" = with lib; {
        target = ".config/smug/willow.yml";
        text =
          generators.toYAML {}
          {
            session = "willow ";
            root = "~/willow/";
            windows = [
              (codeWindow {})
              (terminalWindow {})
              fileManagerWindow
            ];
          };
      };

      "blog.yml" = with lib; {
        target = ".config/smug/blog.yml";
        text =
          generators.toYAML {}
          {
            session = "blog ";
            root = "~/kapa/pro/2022-11-16-amirography_com/amirography/";
            windows = [
              (codeWindow {})
              zolaServeWindow
              (terminalWindow {})
              fileManagerWindow
            ];
          };
      };

      "nvim.yml" = with lib; {
        target = ".config/smug/nvim.yml";
        text =
          generators.toYAML {}
          {
            session = "nvim";
            root = "~/.config/nvim/";
            windows = [
              (codeWindow {commandPrefix = ["nix-shell -p clang"];})
              (terminalWindow {commandPrefix = ["nix-shell -p clang"];})
              fileManagerWindow
            ];
          };
      };

      "proxy.yml" = with lib; {
        target = ".config/smug/proxy.yml";
        text =
          generators.toYAML {}
          {
            session = "proxy ";
            root = "~";
            windows = [
              {
                name = "v2ray";
                commands = ["v2ray run -c ~/vless-hackap.json"];
              }
              {
                name = "arti";
                commands = ["arti proxy"];
              }
            ];
          };
      };

      "jafam-auth.yml" = with lib; {
        target = ".config/smug/jafam-auth.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-auth ";
            root = "~/kapa/pro/jafam2/auth/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };

      "jafam-entry.yml" = with lib; {
        target = ".config/smug/jafam-entry.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-entry ";
            root = "~/kapa/pro/jafam2/entry/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };

      "jafam-models.yml" = with lib; {
        target = ".config/smug/jafam-models.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-models ";
            root = "~/kapa/pro/jafam2/models/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };

      "jafam-rbac.yml" = with lib; {
        target = ".config/smug/jafam-rbac.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-rbac ";
            root = "~/kapa/pro/jafam2/rbac/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };

      "jafam-redisHelper.yml" = with lib; {
        target = ".config/smug/jafam-redisHelper.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-redisHelper ";
            root = "~/kapa/pro/jafam2/redisHelper/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };

      "jafam-session.yml" = with lib; {
        target = ".config/smug/jafam-session.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-session ";
            root = "~/kapa/pro/jafam2/session/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };

      "jafam-user.yml" = with lib; {
        target = ".config/smug/jafam-user.yml";
        text =
          generators.toYAML {}
          {
            session = "jafam-user ";
            root = "~/kapa/pro/jafam2/user/";
            windows = [
              (codeWindow {commandPrefix = [];})
              (terminalWindow {commandPrefix = [];})
              fileManagerWindow
            ];
          };
      };
    };
  };
}
