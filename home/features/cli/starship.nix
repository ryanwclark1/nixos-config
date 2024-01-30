{
  lib,
  config,
  ...
}:
let
  inherit (config.colorscheme) colors slug;
in
# TODO: Add pyenv, nvm, rbenv, rustup, etc. support

{
  # home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      format =  "[](base08)\$os\$username\$hostname\$localip\[](bg:base09 fg:base08)\$directory\[](fg:base09 bg:base0A)\$git_branch\$git_status\[](fg:base0A bg:base0B)\$bun\$c\$cmake\$dart\$golang\$haskell\$java\$kotlin\$kubernetes\$lua\$nodejs\$php\$python\$rust\$swift\$zig[](fg:base0B bg:base07)\$docker_context\[](fg:base07)\$character";
      add_newline = true;
      scan_timeout = 30;
      command_timeout = 500;
      palette = "${slug}";

      palettes.gruvbox_dark ={
        base00 = "#fbf1c7";
        base05 = "#3c3836";
        base07 = "#665c54";
        base08 = "#d65d0e";
        base09 = "#d79921";
        base0A = "#689d6a";
        base0B = "#458588";
        color_green = "#98971a";
        color_yellow = "#d79921";
        color_purple = "#b16286";
        color_red = "#cc241d";
        base0C = "#83a598";
      };

      palettes."${slug}" = {
        base00 = "#${colors.base00}";
        base01 = "#${colors.base01}";
        base02 = "#${colors.base02}";
        base03 = "#${colors.base03}";
        base04 = "#${colors.base04}";
        base05 = "#${colors.base05}";
        base06 = "#${colors.base06}";
        base07 = "#${colors.base07}";
        base08 = "#${colors.base08}";
        base09 = "#${colors.base09}";
        base0A = "#${colors.base0A}";
        base0B = "#${colors.base0B}";
        base0C = "#${colors.base0C}";
        base0D = "#${colors.base0D}";
        base0E = "#${colors.base0E}";
        base0F = "#${colors.base0F}";
        color_green = "#98971a";
        color_yellow = "#d79921";
        color_purple = "#b16286";
        color_red = "#cc241d";
      };


      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;

      os = {
        disabled = false;
        style = "bg:base08 fg:base00";
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
        style_user = "bg:base08 fg:base00";
        style_root = "bg:base08 fg:base00";
        format = "[ $user ]($style)";
      };

      localip = {
        disabled = false;
        ssh_only = true;
        style = "bg:base08 fg:base00";
        format = "[ $localipv4 ]($style)";
      };

      hostname = {
        disabled = false;
        ssh_only = true;
        ssh_symbol = "";
        style = "bg:base08 fg:base00";
        format = "[$ssh_symbol]($style)";
      };

      directory = {
        style = "fg:base00 bg:base09";
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
      shlvl.symbol = "";
      terraform.symbol = "󱁢";

      container = {
        symbol = "";
        style = "fg:base00 bg:base09";
        format = "[$symbol\ [$name]]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:base0A";
        format = "[[ $symbol $branch ](fg:base00 bg:base0A)]($style)";
      };

      git_status = {
        style = "bg:base0A";
        format = "[[($all_status$ahead_behind )](fg:base00 bg:base0A)]($style)";
      };

      bun = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      cmake = {
        symbol = " ";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      dart = {
        symbol = " ";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
        disabled = true;
      };

      golang = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      kubernetes = {
        symbol = "󱃾";
        style = "bg:base0B";
        format = "[[ $symbol$context( \$namespace\ ) ](fg:base00 bg:base0B)]($style)";
      };

      lua = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]";
        disabled = true;
      };

      nodejs = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:base0B";
        version_format = "$raw";
        format = "[ $symbol( $version )(\($virtualenv\) )]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
      };

      swift = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]($style)";
        disabled = true;
      };

      zig = {
        symbol = "";
        style = "bg:base0B";
        format = "[[ $symbol( $version) ](fg:base00 bg:base0B)]";
        disabled = true;
      };

      docker_context = {
        symbol = "";
        style = "bg:base07";
        format = "[[ $symbol( $context) ](fg:base0C bg:base07)]($style)";
      };

      line_break.disabled = true;

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_green)";
        error_symbol = "[](bold fg:color_red)";
        vimcmd_symbol = "[](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
        vimcmd_replace_symbol = "[](bold fg:color_purple)";
        vimcmd_visual_symbol = "[](bold fg:color_yellow)";
      };

      cmd_duration = {
        min_time = 2000;
      };
    };

  };


# { pkgs, lib, ... }:
# {
#   programs.starship = {
#     enable = true;
#     settings = {
#       format =
#         let
#           git = "$git_branch$git_commit$git_state$git_status";
#           cloud = "$aws$gcloud$openstack";
#         in
#         ''
#           $username$hostname($shlvl)($cmd_duration) $fill ($nix_shell)$custom
#           $directory(${git})(- ${cloud}) $fill $time
#           $jobs$character
#         '';

#       fill = {
#         symbol = " ";
#         disabled = false;
#       };

#       # Core
#       username = {
#         format = "[$user]($style)";
#         show_always = true;
#       };
#       hostname = {
#         format = "[@$hostname]($style) ";
#         ssh_only = false;
#         style = "bold green";
#       };
#       shlvl = {
#         format = "[$shlvl]($style) ";
#         style = "bold cyan";
#         threshold = 2;
#         repeat = true;
#         disabled = false;
#       };
#       cmd_duration = {
#         format = "took [$duration]($style) ";
#       };

#       directory = {
#         format = "[$path]($style)( [$read_only]($read_only_style)) ";
#       };
#       nix_shell = {
#         format = "[($name \\(develop\\) <- )$symbol]($style) ";
#         impure_msg = "";
#         symbol = " ";
#         style = "bold red";
#       };
#       # custom = {
#       #   nix_inspect = let
#       #     excluded = [ "kitty" "imagemagick" "ncurses" "user-environment" ];
#       #   in {
#       #     disabled = false;
#       #     when = "test -z $IN_NIX_SHELL";
#       #     command = "${(lib.getExe pkgs.nix-inspect)} ${(lib.concatStringsSep " " excluded)}";
#       #     format = "[($output <- )$symbol]($style) ";
#       #     symbol = " ";
#       #     style = "bold blue";
#       #   };
#       # };

#       character = {
#         error_symbol = "[~~>](bold red)";
#         success_symbol = "[->>](bold green)";
#         vimcmd_symbol = "[<<-](bold yellow)";
#         vimcmd_visual_symbol = "[<<-](bold cyan)";
#         vimcmd_replace_symbol = "[<<-](bold purple)";
#         vimcmd_replace_one_symbol = "[<<-](bold purple)";
#       };

#       time = {
#         format = "\\\[[$time]($style)\\\]";
#         disabled = false;
#       };


#   };
# }
}