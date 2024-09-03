{
  config,
  lib,
  pkgs,
  ...
}:
with config.lib.stylix.colors.withHashtag;
# TODO: Add pyenv, nvm, rbenv, rustup, etc. support

{
  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      format = "[](${base0E})\$os\$username\$hostname\$localip\${custom.yazi}\[](bg:${base07} fg:${base0E})\$directory\[](fg:${base07} bg:${base05})\$git_branch\$git_status\[](fg:${base05} bg:${base0F})\$bun\$c\$cmake\$dart\$golang\$haskell\$java\$kotlin\$kubernetes\$lua\$nodejs\$php\$python\$rust\$swift\$zig[](fg:${base0F} bg:${base06})\$docker_context\[](fg:${base06})\$character";
      add_newline = true;
      scan_timeout = 30;
      command_timeout = 500;
      follow_symlinks = true;

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;

      os = {
        disabled = false;
        style = "bg:${base0E} fg:${base00}";
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
        style_user = "bg:${base0E} fg:${base00}";
        style_root = "bg:${base0E} fg:${base00}";
        format = "[ $user ]($style)";
      };

      localip = {
        disabled = false;
        ssh_only = true;
        style = "bg:${base0E} fg:${base00}";
        format = "[ $localipv4 ]($style)";
      };

      hostname = {
        disabled = false;
        ssh_only = true;
        ssh_symbol = "";
        style = "bg:${base0E} fg:${base00}";
        format = "[$ssh_symbol]($style)";
      };

      directory = {
        style = "fg:${base00} bg:${base07}";
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
        style = "fg:${base00} bg:${base07}";
        format = "[$symbol\ [$name]]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:${base05}";
        format = "[[ $symbol $branch ](fg:${base00} bg:${base05})]($style)";
      };

      git_status = {
        style = "bg:${base05}";
        format = "[[($all_status$ahead_behind )](fg:${base00} bg:${base05})]($style)";
      };

      bun = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      cmake = {
        symbol = " ";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      dart = {
        symbol = " ";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
        disabled = true;
      };

      golang = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      kubernetes = {
        symbol = "󱃾";
        style = "bg:${base0F}";
        format = "[[ $symbol$context( \$namespace\ ) ](fg:${base00} bg:${base0F})]($style)";
      };

      lua = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]";
        disabled = true;
      };

      nodejs = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      php = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      python = {
        symbol = "";
        style = "bg:${base0F}";
        version_format = "$raw";
        format = "[ $symbol( $version )(\($virtualenv\) )]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
      };

      swift = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]($style)";
        disabled = true;
      };

      zig = {
        symbol = "";
        style = "bg:${base0F}";
        format = "[[ $symbol( $version) ](fg:${base00} bg:${base0F})]";
        disabled = true;
      };

      docker_context = {
        symbol = "";
        style = "bg:${base06}";
        format = "[[ $symbol( $context) ](fg:${base0C} bg:${base06})]($style)";
      };

      custom.yazi = {
        description = "Indicate when the shell was launched by `yazi`";
        symbol = " ";
        when = '' test -n "$YAZI_LEVEL" '';
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
