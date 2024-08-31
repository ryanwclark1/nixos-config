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
      format = "[](${base08})\$os\$username\$hostname\$localip\${custom.yazi}\[](bg:${base09} fg:${base08})\$directory\[](fg:${base09} bg:${base0A})\$git_branch\$git_status\[](fg:${base0A} bg:${base0B})\$bun\$c\$cmake\$dart\$golang\$haskell\$java\$kotlin\$kubernetes\$lua\$nodejs\$php\$python\$rust\$swift\$zig[](fg:${base0B} bg:${base01})\$docker_context\[](fg:${base01})\$character";
      add_newline = true;
      scan_timeout = 30;
      command_timeout = 500;
      follow_symlinks = true;

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;

      os = {
        disabled = false;
        style = "bg:${base08} fg:${base04}";
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
        style_user = "bg:${base08} fg:${base04}";
        style_root = "bg:${base08} fg:${base04}";
        format = "[ $user ]($style)";
      };

      localip = {
        disabled = false;
        ssh_only = true;
        style = "bg:${base08} fg:${base04}";
        format = "[ $localipv4 ]($style)";
      };

      hostname = {
        disabled = false;
        ssh_only = true;
        ssh_symbol = "";
        style = "bg:${base08} fg:${base04}";
        format = "[$ssh_symbol]($style)";
      };

      directory = {
        style = "fg:${base04} bg:${base09}";
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
        style = "fg:${base04} bg:${base09}";
        format = "[$symbol\ [$name]]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:${base0A}";
        format = "[[ $symbol $branch ](fg:${base04} bg:${base0A})]($style)";
      };

      git_status = {
        style = "bg:${base0A}";
        format = "[[($all_status$ahead_behind )](fg:${base04} bg:${base0A})]($style)";
      };

      bun = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      cmake = {
        symbol = " ";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      dart = {
        symbol = " ";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
        disabled = true;
      };

      golang = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      kubernetes = {
        symbol = "󱃾";
        style = "bg:${base0B}";
        format = "[[ $symbol$context( \$namespace\ ) ](fg:${base04} bg:${base0B})]($style)";
      };

      lua = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]";
        disabled = true;
      };

      nodejs = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      php = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      python = {
        symbol = "";
        style = "bg:${base0B}";
        version_format = "$raw";
        format = "[ $symbol( $version )(\($virtualenv\) )]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
      };

      swift = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]($style)";
        disabled = true;
      };

      zig = {
        symbol = "";
        style = "bg:${base0B}";
        format = "[[ $symbol( $version) ](fg:${base04} bg:${base0B})]";
        disabled = true;
      };

      docker_context = {
        symbol = "";
        style = "bg:${base01}";
        format = "[[ $symbol( $context) ](fg:${base0C} bg:${base01})]($style)";
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
