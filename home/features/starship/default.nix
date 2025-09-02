{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: Add pyenv, nvm, rbenv, rustup, etc. support
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
    # Configuration written to ~/.config/starship.toml
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
        "[](fg:#${base05} bg:#${base0F})"
        "$python"
        "$bun"
        "$c"
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
      # format = "[](#${base0E})\$os\$username\$hostname\$localip\$container\${custom.yazi}\[](bg:#${base07} fg:#${base0E})\$directory\[](fg:#${base07} bg:#${base05})\$git_branch\$git_status\[](fg:#${base05} bg:#${base0F})\$python\$bun\$c\$cmake\$dart\$golang\$haskell\$java\$kotlin\$kubernetes\$lua\$nodejs\$php\$rust\$swift\$zig[](fg:#${base0F} bg:#${base06})\$docker_context\$nix_shell\[](fg:#${base06})\$fill\[](fg:#${base0E})\$time\[](#${base0E})\$line_break$character";
      add_newline = true;
      line_break.disabled = false;
      scan_timeout = 30;
      command_timeout = 500;
      follow_symlinks = true;

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
        # symbol = " ";
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
      hg_branch.symbol = "";
      julia.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      nim.symbol = "󰆥 ";
      perl.symbol = " ";
      ruby.symbol = " ";
      scala.symbol = "";
      terraform.symbol = "󱁢 ";
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
      # cpp = {
      #   symbol = " ";
      #   style = "bg:#${base0F}";
      #   format = "[[ $symbol( $version) ](fg:#${base00} bg:#${base0F})]($style)";
      #   disabled = false;
      # };
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
        # impure_msg = "impure";
        pure_msg = "";
        # pure_msg = "pure";
        heuristic	= false;
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
        detect_folders = [".venv"];
        python_binary	= ["python" "python3"];
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
        disabled = false;
      };
      custom.yazi = {
        description = "Indicate when the shell was launched by `yazi`";
        symbol = " ";
        style = "bg:#${base0E} fg:#${base00}";
        when = ''test -n "$YAZI_LEVEL"'';
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
