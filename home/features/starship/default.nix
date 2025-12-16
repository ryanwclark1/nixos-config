{
  config,
  lib,
  pkgs,
  ...
}:

let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in
{
  programs.starship = {
    enable = true;
    package = pkgs.starship;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
    enableIonIntegration = lib.mkIf config.programs.ion.enable true;

    settings = {
      format = lib.concatStrings [
        "[](fg:#${base0E})"
        "$os"
        "$username"
        "$hostname"
        "$localip"
        "$container"
        "[](bg:#${base07} fg:#${base0E})"
        "$directory"
        "[](fg:#${base07} bg:#${base05})"
        "$git_branch"
        "$git_status"
        # "$git_state"
        # "$git_commit"
        "[](fg:#${base05} bg:#${base0F})"
        "$python"
        "$bun"
        "$c"
        "$cpp"
        "$cmake"
        "$dart"
        "$deno"
        "$golang"
        "$haskell"
        "$java"
        "$kotlin"
        "$kubernetes"
        "$lua"
        "$nodejs"
        "$php"
        "$rust"
        "$swift"
        "$zig"
        "[](fg:#${base0F} bg:#${base06})"
        "$docker_context"
        "$nix_shell"
        "[](fg:#${base06})"
        "$fill"
        "[](fg:#${base0E})"
        "$time"
        "[](fg:#${base0E})"
        "$line_break"
        "$character"
      ];

      # right_format = lib.concatStrings [
      #   "$git_metrics"
      #   "$jobs"
      #   "$status"
      #   "$sudo"
      #   "$battery"
      #   "$memory_usage"
      #   "$time"
      # ];

      add_newline = true;
      line_break.disabled = false;
      # continuation_prompt = "[▶](bold #${base0E}) ";
      scan_timeout = 30;
      command_timeout = 500;
      follow_symlinks = true;
      # use_accent_color = true;
      # true_color = true;

      os = {
        disabled = false;
        style = "bg:#${base0E} fg:#${base00}";
        format = "[$symbol]($style)";
        symbols = {
          AlmaLinux = " ";
          Alpine = " ";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = " ";
          Debian = " ";
          Fedora = "󰣛 ";
          FreeBSD = " ";
          Gentoo = "󰣨 ";
          Kali = " ";
          Linux = "󰌽 ";
          Macos = "󰀵";
          Manjaro = " ";
          Mint = "󰣭 ";
          NixOS = " ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = "󱄛 ";
          RockyLinux = " ";
          SUSE = " ";
          Ubuntu = "󰕈 ";
          Unknown = "";
          Void = " ";
          Windows = "󰍲 ";
        };
      };

      username = {
        show_always = true;
        disabled = false;
        detect_env_vars = [
          "SSH_CONNECTION"
          "SSH_CLIENT"
          "SSH_TTY"
        ];
        style_user = "bg:#${base0E} fg:#${base00}";
        style_root = "bg:#${base0E} fg:#${base00}";
        format = "[ $user ]($style)";
      };

      localip = {
        disabled = false;
        ssh_only = true;
        style = "bg:#${base0E} fg:#${base00}";
        format = "[ $localipv4 ]($style)";
      };

      hostname = {
        disabled = false;
        ssh_only = true;
        ssh_symbol = " ";
        style = "bg:#${base0E} fg:#${base00}";
        format = "[$ssh_symbol]($style)";
      };

      container = {
        symbol = " ";
        style = "bg:#${base0E} fg:#${base00}";
        format = "[ $symbol $name ]($style)";
        disabled = false;
      };

      directory = {
        style = "fg:#${base00} bg:#${base07}";
        format = "[$path]($style)";
        truncation_length = 10;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " ";
        home_symbol = "~";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          "Code" = "󰲋 ";
          "Videos" = " ";
          "Desktop" = " ";
        };
      };

      gcloud = {
        disabled = true;
        format = "on [$symbol$active(/$project)(\\($region\\))]($style)";
        symbol = "󱇶 ";
      };
      aws = {
        disabled = true;
        symbol = " ";
        format = "on [$symbol$profile(\\($region\\))]($style)";
      };
      azure = {
        disabled = true;
        symbol = " ";
        format = "on [$symbol$subscription]($style)";
      };

      conda = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol($environment) ](fg:#${base00} bg:#${base0F})]($style)";
        ignore_base = true;
        disabled = false;
      };
      hg_branch.symbol = "";
      julia.symbol = " ";
      nim.symbol = "󰆥 ";
      perl.symbol = " ";
      ruby.symbol = " ";
      scala.symbol = "";
      terraform = {
        symbol = "󱁢 ";
        style = "bg:#${base0F}";
        format = "[[ $symbol($workspace) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      rlang.symbol = " ";

      shlvl = {
        symbol = " ";
        style = "bg:#${base05}";
        format = "[$shlvl]($style) ";
        threshold = 2;
        repeat = true;
        disabled = false;
      };

      git_branch = {
        symbol = "";
        style = "bg:#${base05}";
        format = "[[ $symbol$branch ](fg:#${base00} bg:#${base05})]($style)";
        disabled = false;
      };
      git_status = {
        style = "bg:#${base05}";
        format = "[[($all_status$ahead_behind )](fg:#${base00} bg:#${base05})]($style)";
        disabled = false;
      };
      git_commit = {
        commit_hash_length = 7;
        style = "bg:#${base05} fg:#${base00}";
        format = "[[($hash$tag)](fg:#${base00} bg:#${base05})]($style)]";
        only_detached = true;
        disabled = true;
      };
      git_state = {
        rebase = "REBASING";
        merge = "MERGING";
        revert = "REVERTING";
        cherry_pick = "CHERRY-PICKING";
        bisect = "BISECTING";
        am = "AM";
        am_or_rebase = "AM/REBASE";
        style = "bg:#${base08} bold";
        format = "[[\($state( $progress_current/$progress_total)\)]($style)]";
        disabled = true;
      };
      git_metrics = {
        added_style = "bold #${base0B}";
        deleted_style = "bold #${base08}";
        only_nonzero_diffs = true;
        disabled = true;
      };
      package = {
        symbol = "󰏗 ";
        style = "bg:#${base0F}";
        version_format = "v$raw";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      bun = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      c = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      cpp = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      cmake = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
      };
      dart = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = true;
      };
      deno = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      dotnet = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      elixir = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      elm = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      erlang = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      golang = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      haskell = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
      };
      java = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = true;
      };
      kotlin = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = true;
      };
      kubernetes = {
        symbol = "󱃾 ";
        style = "bg:#${base0F}";
        format = "[[ $symbol$context( \$namespace\ ) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
        detect_env_vars = [ "KUBECONFIG" ];
        detect_files = [
          "kubeconfig"
          "kustomization.yaml"
          "kustomization.yml"
        ];
        detect_folders = [ ".kube" ];
      };
      lua = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      nix_shell = {
        symbol = " ";
        style = "bg:#${base06}";
        format = "[[$symbol$state( \($name\))](fg:#${base00} bg:#${base06})]($style)";
        impure_msg = "";
        pure_msg = "";
        heuristic = false;
        disabled = true;
      };
      nodejs = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol($version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      php = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      python = {
        symbol = " ";
        style = "bg:#${base0F}";
        version_format = "$raw";
        format = "[[ $symbol($version) (\($virtualenv\))](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
        detect_folders = [ ".venv" ];
        python_binary = [
          "python"
          "python3"
        ];
        pyenv_version_name = false;
      };
      rust = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = false;
      };
      swift = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = true;
      };
      zig = {
        symbol = " ";
        style = "bg:#${base0F}";
        format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
        disabled = true;
      };
      docker_context = {
        symbol = " ";
        style = "fg:#${base00} bg:#${base06}";
        format = "[ $symbol( $context) ]($style)";
        only_with_files = true;
        detect_files = [
          "docker-compose.yml"
          "docker-compose.yaml"
          "Dockerfile"
          ".dockerignore"
        ];
        detect_folders = [ ".docker" ];
        disabled = false;
      };
      custom.yazi = {
        description = "Indicate when the shell was launched by `yazi`";
        symbol = " ";
        style = "bg:#${base0E} fg:#${base00}";
        when = ''test -n "$YAZI_LEVEL"'';
        format = "[$symbol yazi]($style) ";
        disabled = false;
      };

      # Custom module for NixOS flake detection
      custom.nix_flake = {
        description = "Show when in a Nix flake directory";
        symbol = "󱄅 ";
        style = "bg:#${base0E} fg:#${base00}";
        when = ''test -f flake.nix || test -f flake.lock'';
        format = "[$symbol]($style)";
        disabled = true;
      };

      # Custom module for Git worktree detection
      custom.git_worktree = {
        description = "Show when in a git worktree";
        symbol = "󰧨 ";
        style = "bg:#${base05} fg:#${base00}";
        when = ''git rev-parse --git-dir 2>/dev/null | grep -q worktrees'';
        format = "[$symbol]($style)";
        disabled = true;
      };
      character = {
        error_symbol = "[~>](bold #${base08})";
        success_symbol = "[](bold #${base0B})";
        vimcmd_symbol = "[](bold #${base0B})";
        vimcmd_visual_symbol = "[](bold #${base0A})";
        vimcmd_replace_symbol = "[](bold #${base0E})";
        vimcmd_replace_one_symbol = "[](bold #${base0E})";
      };
      cmd_duration = {
        min_time = 2000;
        style = "bg:#${base0E} fg:#${base00} bold";
        format = "[$duration]($style) ";
        show_milliseconds = false;
        show_notifications = false;
        disabled = true;
      };
      jobs = {
        number_threshold = 1;
        symbol_threshold = 1;
        format = "[$symbol$number]($style) ";
        symbol = "󰆍 ";
        style = "bg:#${base0E} fg:#${base00} bold";
        disabled = true;
      };
      status = {
        symbol = "󰅛";
        not_executable_symbol = "󰚌";
        not_found_symbol = "󰍉";
        sigint_symbol = "󰟾";
        signal_symbol = "󰐊";
        format = "[$symbol$common_meaning$signal_name$maybe_int]($style) ";
        map_symbol = true;
        disabled = true;
        recognize_signal_code = true;
      };
      sudo = {
        symbol = "󰚀 ";
        style = "bg:#${base08} bold";
        format = "[$symbol]($style)";
        allow_windows = false;
        disabled = true;
      };
      battery = {
        full_symbol = "󰁹 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󰁺 ";
        unknown_symbol = "󰂑 ";
        empty_symbol = "󰂎 ";
        disabled = true;
        format = "[$symbol$percentage]($style) ";
        display = [
          {
            threshold = 10;
            style = "bold #${base08}";
          }
          {
            threshold = 30;
            style = "bold #${base0A}";
          }
        ];
      };
      memory_usage = {
        symbol = "󰍛 ";
        format = "[$symbol$ram_pct]($style) ";
        style = "bold #${base0E}";
        disabled = true;
        threshold = 75;
      };
      fill = {
        symbol = " ";
        style = "bg:none fg:none";
      };
      time = {
        style = "bg:#${base0E} fg:#${base00}";
        format = "[ $time]($style)";
        use_12hr = false;
        disabled = false;
      };
    };
  };
}
