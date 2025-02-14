{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: Add pyenv, nvm, rbenv, rustup, etc. support

{
  programs.starship = {
    enable = true;
    package = pkgs.starship;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
    enableIonIntegration = lib.mkIf config.programs.ion.enable true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      format = "[](#ca9ee6)\$os\$username\$hostname\$localip\$container\${custom.yazi}\[](bg:#babbf1 fg:#ca9ee6)\$directory\[](fg:#babbf1 bg:#c6d0f5)\$git_branch\$git_status\[](fg:#c6d0f5 bg:#eebebe)\$python\$bun\$c\$cmake\$dart\$golang\$haskell\$java\$kotlin\$kubernetes\$lua\$nodejs\$php\$rust\$swift\$zig[](fg:#eebebe bg:#f2d5cf)\$docker_context\$nix_shell\[](fg:#f2d5cf)\$fill\[](fg:#ca9ee6)\$time\[](#ca9ee6)\$line_break$character";
      add_newline = true;
      line_break.disabled = false;
      scan_timeout = 30;
      command_timeout = 500;
      follow_symlinks = true;

      os = {
        disabled = false;
        style = "bg:#ca9ee6 fg:#303446";
        format = "[$symbol]($style)";
        symbols = {
          AlmaLinux = " ";
          Alpine = " ";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = " ";
          Debian = "󰣚 ";
          Fedora = "󰣛 ";
          FreeBSD = " ";
          Gentoo = "󰣨 ";
          Kali = " ";
          Linux = "󰌽 ";
          Macos = "󰀵 ";
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
        style_user = "bg:#ca9ee6 fg:#303446";
        style_root = "bg:#ca9ee6 fg:#303446";
        format = "[ $user ]($style)";
      };

      localip = {
        disabled = false;
        ssh_only = true;
        style = "bg:#ca9ee6 fg:#303446";
        format = "[ $localipv4 ]($style)";
      };

      hostname = {
        disabled = false;
        ssh_only = true;
        ssh_symbol = " ";
        style = "bg:#ca9ee6 fg:#303446";
        format = "[$ssh_symbol]($style)";
      };

      container = {
        symbol = " ";
        style = "bg:#ca9ee6 fg:#303446";
        format = "[$symbol \[$name\]]($style)";
        disabled = false;
      };

      directory = {
        style = "fg:#303446 bg:#babbf1";
        format = "[ $path ]($style)";
        truncation_length = 8;
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

      # Cloud
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

      # Icon changes only
      conda.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      hg_branch.symbol = " ";
      julia.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      nim.symbol = "󰆥 ";
      perl.symbol = " ";
      ruby.symbol = " ";
      scala.symbol = "";
      terraform.symbol = "󱁢 ";
      erlang.symbol = " ";
      rlang.symbol = " ";

      shlvl = {
        symbol = " ";
        format = "[$shlvl]($style) ";
        style = "bold cyan";
        threshold = 2;
        repeat = true;
        disabled = false;
      };

      git_branch = {
        symbol = " ";
        style = "bg:#c6d0f5";
        format = "[[ $symbol $branch ](fg:#303446 bg:#c6d0f5)]($style)";
        disabled = false;
      };
      git_status = {
        style = "bg:#c6d0f5";
        format = "[[($all_status$ahead_behind )](fg:#303446 bg:#c6d0f5)]($style)";
        disabled = false;
      };
      package = {
        symbol = "󰏗 ";
        version_format = "v$raw";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      bun = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      c = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      cmake = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
      };
      dart = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = true;
      };
      golang = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      haskell = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
      };
      java = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = true;
      };
      kotlin = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = true;
      };
      kubernetes = {
        symbol = "󱃾 ";
        style = "bg:#eebebe";
        format = "[[ $symbol$context( \$namespace\ ) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      lua = {
        symbol = "";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      nix_shell = {
        symbol = " ";
        style = "bg:#f2d5cf";
        format = "[[$symbol$state( \($name\))](fg:#303446 bg:#f2d5cf)]($style)";
        impure_msg = "";
        # impure_msg = "impure";
        pure_msg = "";
        # pure_msg = "pure";
        heuristic	= false;
        disabled = true;
      };
      nodejs = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      php = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      python = {
        symbol = " ";
        style = "bg:#eebebe";
        version_format = "$raw";
        format = "[[ $symbol( $version )(\($virtualenv\) )](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
        detect_folders = [".venv"];
        pyenv_version_name = true;
      };
      rust = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = false;
      };
      swift = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = true;
      };
      zig = {
        symbol = " ";
        style = "bg:#eebebe";
        format = "[[ $symbol( $version) ](fg:#303446 bg:#eebebe)]($style)";
        disabled = true;
      };
      docker_context = {
        symbol = " ";
        style = "fg:#303446 bg:#f2d5cf";
        format = "[ $symbol( $context) ]($style)";
        disabled = false;
      };
      custom.yazi = {
        description = "Indicate when the shell was launched by `yazi`";
        symbol = " ";
        style = "bg:#ca9ee6 fg:#303446";
        when = ''test -n "$YAZI_LEVEL"'';
      };
      character = {
        error_symbol = "[~>](bold #e78284)";
        success_symbol = "[](bold #a6d189)";
        vimcmd_symbol = "[](bold #a6d189)";
        vimcmd_visual_symbol = "[](bold #e5c890)";
        vimcmd_replace_symbol = "[](bold #ca9ee6)";
        vimcmd_replace_one_symbol = "[](bold #ca9ee6)";
      };
      cmd_duration = {
        min_time = 2000;
      };
      fill = {
        symbol = " ";
        style = "bg:none fg:none";
      };
      time = {
        style = "bg:#ca9ee6 fg:#303446";
        format = "[[  $time ](bg:#ca9ee6 fg:#303446)]($style)";
        use_12hr = false;
        disabled = false;
      };
    };
  };
}
