{
  config,
  ...
}:
# let
#   inherit (config.colorscheme) palette;
# in
# TODO: Add pyenv, nvm, rbenv, rustup, etc. support

{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      format = "[](color_a1)\$os\$username\$hostname\$localip\[](bg:color_a2 fg:color_a1)\$directory\[](fg:color_a2 bg:color_a3)\$git_branch\$git_status\[](fg:color_a3 bg:color_a4)\$bun\$c\$cmake\$dart\$golang\$haskell\$java\$kotlin\$kubernetes\$lua\$nodejs\$php\$python\$rust\$swift\$zig[](fg:color_a4 bg:color_bg3)\$docker_context\[](fg:color_bg3)\$character";
      add_newline = true;
      scan_timeout = 30;
      command_timeout = 500;
      palette = "gruvbox_dark";

      palettes.gruvbox_dark = {
        color_fg0 = "#fbf1c7";
        color_bg1 = "#3c3836";
        color_bg3 = "#665c54";
        color_a1 = "#d65d0e";
        color_a2 = "#d79921";
        color_a3 = "#689d6a";
        color_a4 = "#458588";
        color_green = "#98971a";
        color_yellow = "#d79921";
        color_purple = "#b16286";
        color_red = "#cc241d";
        color_docker = "#83a598";
      };

      # palettes.system = {
      #   color_fg0 = "#${palette.base00}";
      #   color_bg1 = "#${palette.base05}";
      #   color_bg3 = "#${palette.base07}";
      #   color_a1 = "#${palette.base08}";
      #   color_a2 = "#${palette.base09}";
      #   color_a3 = "#${palette.base0A}";
      #   color_a4 = "#${palette.base0B}";
      #   color_docker = "#${palette.base0C}";
      #   color_green = "#${palette.base0B}";
      #   color_yellow = "#${palette.base0A}";
      #   color_purple = "#${palette.base0E}";
      #   color_red = "#${palette.base08}";
      # };

      palettes.nord_dark = {
        color_fg0 = "#d8dee9";
        color_bg1 = "#2e3440";
        color_bg3 = "#3b4252";
        color_a1 = "#bf616a";
        color_a2 = "#d08770";
        color_a3 = "#ebcb8b";
        color_a4 = "#a3be8c";
        color_green = "#a3be8c";
        color_yellow = "#ebcb8b";
        color_purple = "#b48ead";
        color_red = "#bf616a";
        color_docker = "#88c0d0";
      };

      palettes.nord_light = {
        color_fg0 = "#2e3440";
        color_bg1 = "#d8dee9";
        color_bg3 = "#eceff4";
        color_a1 = "#bf616a";
        color_a2 = "#d08770";
        color_a3 = "#ebcb8b";
        color_a4 = "#a3be8c";
        color_green = "#a3be8c";
        color_yellow = "#ebcb8b";
        color_purple = "#b48ead";
        color_red = "#bf616a";
        color_docker = "#88c0d0";
      };

      palettes.gruvbox_light = {
        color_fg0 = "#3c3836";
        color_bg1 = "#fbf1c7";
        color_bg3 = "#d5c4a1";
        color_a1 = "#d65d0e";
        color_a2 = "#d79921";
        color_a3 = "#689d6a";
        color_a4 = "#458588";
        color_green = "#98971a";
        color_yellow = "#d79921";
        color_purple = "#b16286";
        color_red = "#cc241d";
        color_docker = "#83a598";
      };
      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;

      os = {
        disabled = false;
        style = "bg:color_a1 fg:color_fg0";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          NixOS = "";
        };
      };

      username = {
        show_always = true;
        disabled = false;
        style_user = "bg:color_a1 fg:color_fg0";
        style_root = "bg:color_a1 fg:color_fg0";
        format = "[ $user ]($style)";
      };

      localip = {
        disabled = false;
        ssh_only = true;
        style = "bg:color_a1 fg:color_fg0";
        format = "[ $localipv4 ]($style)";
      };

      hostname = {
        disabled = false;
        ssh_only = true;
        ssh_symbol = "";
        style = "bg:color_a1 fg:color_fg0";
        format = "[$ssh_symbol]($style)";
      };

      directory = {
        style = "fg:color_fg0 bg:color_a2";
        format = "[ $path ]($style)";
        truncation_length = 8;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = "";
        home_symbol = "~";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
          "code" = "󰲋 ";
        };
      };


      # Cloud
      gcloud = {
        format = "on [$symbol$active(/$project)(\\($region\\))]($style)";
      };
      aws = {
        format = "on [$symbol$profile(\\($region\\))]($style)";
      };

      # Icon changes only \/
      aws.symbol = "  ";
      conda.symbol = " ";
      # directory.read_only = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      gcloud.symbol = " ";
      hg_branch.symbol = " ";
      julia.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      nim.symbol = "󰆥 ";
      # nodejs.symbol = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      ruby.symbol = " ";
      scala.symbol = " ";
      terraform.symbol = "󱁢";

      shlvl = {
        symbol = "";
        format = "[$shlvl]($style) ";
        style = "bold cyan";
        threshold = 2;
        repeat = true;
        disabled = false;
      };

      container = {
        symbol = "";
        style = "fg:color_fg0 bg:color_a2";
        format = "[$symbol\ [$name]]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:color_a3";
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_a3)]($style)";
      };

      git_status = {
        style = "bg:color_a3";
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_a3)]($style)";
      };

      bun = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      cmake = {
        symbol = " ";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      dart = {
        symbol = " ";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
        disabled = true;
      };

      golang = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      kubernetes = {
        symbol = "󱃾";
        style = "bg:color_a4";
        format = "[[ $symbol$context( \$namespace\ ) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      lua = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]";
        disabled = true;
      };

      nodejs = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:color_a4";
        version_format = "$raw";
        format = "[ $symbol( $version )(\($virtualenv\) )]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
      };

      swift = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]($style)";
        disabled = true;
      };

      zig = {
        symbol = "";
        style = "bg:color_a4";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_a4)]";
        disabled = true;
      };

      docker_context = {
        symbol = "";
        style = "bg:color_bg3";
        format = "[[ $symbol( $context) ](fg:color_docker bg:color_bg3)]($style)";
      };

      line_break.disabled = true;

      # character = {
      #   error_symbol = "[~~>](bold red)";
      #   success_symbol = "[->>](bold green)";
      #   vimcmd_symbol = "[<<-](bold yellow)";
      #   vimcmd_visual_symbol = "[<<-](bold cyan)";
      #   vimcmd_replace_symbol = "[<<-](bold purple)";
      #   vimcmd_replace_one_symbol = "[<<-](bold purple)";
      # };

      character = {
        error_symbol = "[~>](bold red)";
        success_symbol = "[](bold green)";
        vimcmd_symbol = "[](bold yellow)";
        vimcmd_visual_symbol = "[](bold cyan)";
        vimcmd_replace_symbol = "[](bold purple)";
        vimcmd_replace_one_symbol = "[](bold purple)";
      };

      cmd_duration = {
        min_time = 2000;
      };

      time = {
        format = "\\\[[$time]($style)\\\]";
        disabled = false;
      };
    };

  };
}
