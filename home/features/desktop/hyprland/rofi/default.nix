{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
# TODO: Fix ssh functionality
{
  imports = [
    ./scripts
  ];


  home.file.".config/rofi/applets" = {
    source = ./applets;
    recursive = true;
  };

  home.file.".config/rofi/powermenu" = {
    source = ./powermenu;
    recursive = true;
  };

  home.file = {
    # ".config/rofi/custom.rasi" = {
    #   source = ./custom.rasi;
    # };
    ".config/rofi/config2.rasi" = {
      source = ./config2.rasi;
    };
    ".config/rofi/style/applet2-1.rasi" = {
      source = ./style/applet2-1.rasi;
    };
    ".config/rofi/style/applet2-2.rasi" = {
      source = ./style/applet2-2.rasi;
    };
    ".config/rofi/style/applet2-3.rasi" = {
      source = ./style/applet2-3.rasi;
    };
    ".config/rofi/style/applet3-1.rasi" = {
      source = ./style/applet3-1.rasi;
    };
    ".config/rofi/style/applet3-2.rasi" = {
      source = ./style/applet3-2.rasi;
    };
    ".config/rofi/style/applet3-3.rasi" = {
      source = ./style/applet3-3.rasi;
    };
    ".config/rofi/style/cliphist-2.rasi" = {
      source = ./style/cliphist-2.rasi;
    };
    ".config/rofi/style/cliphist.rasi" = {
      source = ./style/cliphist.rasi;
    };
    ".config/rofi/style/config-emoji.rasi" = {
      source = ./style/config-emoji.rasi;
    };
    ".config/rofi/style/config-long.rasi" = {
      source = ./style/config-long.rasi;
    };
    ".config/rofi/style/launcher-center-alt1.rasi" = {
      source = ./style/launcher-center-alt1.rasi;
    };
    ".config/rofi/style/launcher-center-alt2.rasi" = {
      source = ./style/launcher-center-alt2.rasi;
    };
    ".config/rofi/style/launcher-center.rasi" = {
      source = ./style/launcher-center.rasi;
    };
    ".config/rofi/style/launcher-full.rasi" = {
      source = ./style/launcher-full.rasi;
    };
    ".config/rofi/style/launcher-long.rasi" = {
      source = ./style/launcher-long.rasi;
    };
    ".config/rofi/style/power-big.rasi" = {
      source = ./style/power-big.rasi;
    };
    ".config/rofi/style/power-small-round.rasi" = {
      source = ./style/power-small-round.rasi;
    };
    ".config/rofi/style/power-small-square.rasi" = {
      source = ./style/power-small-square.rasi;
    };
    ".config/rofi/style/shared/border.rasi" = {
      source = ./style/shared/border.rasi;
    };
    ".config/rofi/style/shared/colors.rasi" = {
      source = ./style/shared/colors.rasi;
    };
    ".config/rofi/style/shared/confirm-big.rasi" = {
      source = ./style/shared/confirm-big.rasi;
    };
    ".config/rofi/style/shared/confirm.rasi" = {
      source = ./style/shared/confirm.rasi;
    };
    ".config/rofi/style/shared/fonts.rasi" = {
      source = ./style/shared/fonts.rasi;
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = [
      pkgs.rofi-emoji-wayland
    ];
    pass = {
      enable = true;
      package = pkgs.rofi-pass-wayland;
      stores = [
        "${config.home.homeDirectory}/.local/share/keyrings"
      ];
    };
    # configPath = "${config.xdg.configHome}/rofi/config.rasi";
    cycle = true;
    xoffset = 0;
    yoffset = 0;
    location = "center";
    terminal = "ghostty";
    
    theme = let 
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        background = "#303446";
        background-alt = "#303446";
        foreground = "#c6d0f5";
        selected = "#8caaee";
        active = "#a6d189";
        urgent = "#e78284";
        base00 = "#303446";
        base01 = "#292c3c";
        base02 = "#414559";
        base03 = "#51576d";
        base04 = "#626880";
        base05 = "#c6d0f5";
        base06 = "#f2d5cf";
        base07 = "#babbf1";
        base08 = "#e78284";
        base09 = "#ef9f76";
        base0A = "#e5c890";
        base0B = "#a6d189";
        base0C = "#81c8be";
        base0D = "#8caaee";
        base0E = "#ca9ee6";
        base0F = "#eebebe";
      };

      window = {
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        x-offset = mkLiteral "0px";
        y-offset = mkLiteral "0px";
        width = mkLiteral "800px";
        height = mkLiteral "600px";
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        border = mkLiteral "0px solid";
        border-radius = mkLiteral "0px";
        background-color = mkLiteral "@background";
      };

      mainbox = {
        children = map mkLiteral [ "inputbar" "message" "listview" ];
        spacing = mkLiteral "15px";
        margin = mkLiteral "0px";
        padding = mkLiteral "30px";
        background-color = mkLiteral "transparent";
      };

      inputbar = {
        children = map mkLiteral [ "textbox-prompt-colon" "prompt" ];
        spacing = mkLiteral "10px";
        padding = mkLiteral "0px";
        border-radius = mkLiteral "0px";
        background-color = mkLiteral "@background-alt";
      };

      textbox-prompt-colon = {
        expand = false;
        str = " = ";
        padding = mkLiteral "10px 13px";
        border-radius = mkLiteral "0px";
        background-color = mkLiteral "@urgent";
      };

      prompt = {
        padding = mkLiteral "10px 13px 10px 10px";
      };

      listview = {
        lines = 12;
      };
    };
    #  + (optionalString (themeName != null) (toRasi { "@theme" = themeName; }));
    # theme = let
    #   # Use `mkLiteral` for string-like values that should show without
    #   # quotes, e.g.:
    #   # {
    #   #   foo = "abc"; =&gt; foo = "abc";
    #   #   bar = mkLiteral "abc"; =&gt; bar: abc;
    #   # };
    #   inherit (config.lib.formats.rasi) mkLiteral;
    # in {
    #   "*" = {
    #     background = mkLiteral "#303446";
    #     background-alt = mkLiteral "rgba(48, 52, 70, .50)";
    #     foreground = mkLiteral "#c6d0f5";
    #     selected = mkLiteral "#8caaee";
    #     active = mkLiteral "#a6d189";
    #     urgent = mkLiteral "#e78284";
    #     width = 512;
    #   };

    #   "#inputbar" = {
    #     children = map mkLiteral [ "prompt" "entry" ];
    #   };

    #   "#textbox-prompt-colon" = {
    #     expand = false;
    #     str = ":";
    #     margin = mkLiteral "0px 0.3em 0em 0em";
    #     text-color = mkLiteral "@foreground-color";
    #   };
    # };
    extraConfig = {
      modi = "drun,emoji,ssh,run,filebrowser,window";
      font = "Fira Code 12";
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
      case-sensitive = false;
      cycle = true;
      filter = "";
      scroll-method = 0;
      normalize-match = true;
      show-icons = true;
      icon-theme = "Papirus";
      steal-focus = false;
      matching = "normal";
      tokenize = true;
      ssh-client = "ssh";
      ssh-command = "{terminal} -e {ssh-client} {host} [-p {port}]";
      parse-hosts = true;
      parse-known-hosts = true;
      drun-categories = "";
      drun-match-fields = "name,generic,exec,categories,keywords";
      drun-display-format = "{name} [<span weight='light' size='small'><i>({generic})</i></span>]";
      drun-show-actions = false;
      drun-url-launcher = "xdg-open";
      drun-use-desktop-cache = false;
      drun-reload-desktop-cache = false;
    };
  };
}