{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;

    # Environment variables
    environmentVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BROWSER = "firefox";
      TERM = "xterm-256color";
      
      # Development
      CARGO_HOME = "${config.home.homeDirectory}/.cargo";
      RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
      GOPATH = "${config.home.homeDirectory}/go";
      
      # XDG Base Directories
      XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
      XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
      XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
      XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    };

    # Shell aliases
    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      
      # Git shortcuts
      g = "git";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gd = "git diff";
      gl = "git log";
      gp = "git push";
      gs = "git status";
      gst = "git status";
      
      # System management
      rebuild = "sudo nixos-rebuild switch --flake .#$(hostname)";
      update = "nix flake update";
      cleanup = "sudo nix-collect-garbage -d";
      
      # Better defaults (cat/ls aliases handled by bat/eza modules)
      grep = "rg";
      find = "fd";
      
      # Docker
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      
      # Development
      vim = "nvim";
      vi = "nvim";
      code = "code --enable-features=UseOzonePlatform --ozone-platform=wayland";
      
      # Quick edits
      zshrc = "nvim ~/.zshrc";
      bashrc = "nvim ~/.bashrc";
      nuconfig = "nvim ~/.config/nushell/config.nu";
    };

    # Nushell-specific settings
    settings = {
      show_banner = false;
      
      edit_mode = "vi";
      
      table = {
        mode = "rounded";
        index_mode = "always";
        header_on_separator = true;
      };
      
      history = {
        max_size = 100000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
      
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
        external = {
          enable = true;
          max_results = 100;
        };
      };
      
      filesize = {
        metric = true;
        format = "auto";
      };
      
      rm = {
        always_trash = true;
      };
    };

    # Extra configuration for config.nu
    extraConfig = ''
      # Custom functions
      def greet [] {
        let time = (date now | date format "%H:%M")
        let user = $env.USER
        let host = (sys | get host.hostname)
        echo $"Hello, ($user)! It's ($time) on ($host)"
      }

      # Better cd with zoxide integration
      def-env z [...args] {
        let result = (zoxide query ...$args | str trim)
        cd $result
      }

      # Git branch in prompt
      def git_branch [] {
        if (git rev-parse --git-dir | complete).exit_code == 0 {
          let branch = (git branch --show-current | str trim)
          if ($branch | is-empty) {
            "(detached)"
          } else {
            $branch
          }
        } else {
          ""
        }
      }

      # Custom prompt
      $env.PROMPT_COMMAND = {||
        let dir = (pwd | path parse | get stem)
        let branch = (git_branch)
        let branch_str = if ($branch | is-empty) { "" } else { $" \(($branch)\)" }
        $"(ansi green_bold)($dir)(ansi reset)($branch_str) "
      }

      $env.PROMPT_INDICATOR = {|| "> " }
      $env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
      $env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
      $env.PROMPT_MULTILINE_INDICATOR = {|| "... " }

      # Useful keybindings
      $env.config = ($env.config | upsert keybindings [
        {
          name: completion_menu
          modifier: control
          keycode: char_n
          mode: vi_insert
          event: {
            until: [
              { send: menu name: completion_menu }
              { send: menupagenext }
            ]
          }
        }
        {
          name: history_menu
          modifier: control
          keycode: char_r
          mode: vi_insert
          event: { send: menu name: history_menu }
        }
      ])

      # Load starship prompt if available
      if (which starship | complete).exit_code == 0 {
        use ~/.cache/starship/init.nu
      }
    '';

    # Extra environment configuration
    extraEnv = ''
      # Path configuration
      $env.PATH = ($env.PATH | split row (char esep) | append [
        $"($env.HOME)/.local/bin"
        $"($env.HOME)/.cargo/bin"
        $"($env.HOME)/go/bin"
        "/usr/local/bin"
      ] | uniq)

      # FZF configuration
      $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
      $env.FZF_DEFAULT_OPTS = "--height 40% --reverse --border --info=inline"
      $env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
      $env.FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git"

      # Bat configuration
      $env.BAT_THEME = "Catppuccin-frappe"
      $env.BAT_STYLE = "numbers,changes,header"

      # Eza configuration  
      $env.EZA_COLORS = "uu=36:gu=37:sn=32:sb=32:da=34:ur=34:uw=35:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36"

      # Load secrets if available
      if ("/home/administrator/.env" | path exists) {
        open /home/administrator/.env | lines | each {|line|
          if ($line | str starts-with "#") {
            # Skip comments
          } else if ($line | str contains "=") {
            let parts = ($line | split row "=" | str trim)
            if ($parts | length) >= 2 {
              let key = ($parts | get 0)
              let val = ($parts | skip 1 | str join "=")
              load-env { $key: $val }
            }
          }
        }
      }
    '';

    # Login configuration
    extraLogin = ''
      # Display system info on login
      if (which fastfetch | complete).exit_code == 0 {
        fastfetch
      }
      
      # Check for updates
      echo "Checking for system updates..."
      let outdated = (nix store diff-closures /run/current-system /run/booted-system | lines | length)
      if $outdated > 0 {
        echo $"(ansi yellow)System has ($outdated) pending updates. Run 'rebuild' to apply.(ansi reset)"
      }
    '';

    # Plugins configuration
    plugins = with pkgs.nushellPlugins; [
      formats
      gstat
      query
    ];
  };

  # Create necessary directories
  home.file.".config/nushell/.keep".text = "";
}