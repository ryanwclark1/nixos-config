{
  config,
  # lib,
  pkgs,
  ...
}:
let 
  inherit (config.lib.formats.rasi) mkLiteral;
in
# with lib;
# TODO: Fix ssh functionality
{
  imports = [
    ./scripts
    ./colors.rasi.nix
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
    ".config/rofi/style/app-toggle.rasi" = {
      source = ./style/app-toggle.rasi;
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
    # ".config/rofi/style/shared/colors.rasi" = {
    #   source = ./style/shared/colors.rasi;
    # };
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
    location = "center";
    terminal = "ghostty";
    theme = {
      "*" = {
        font ="UbuntuMono Nerd Font 14";
        background = mkLiteral "#303446";
        background-alt = mkLiteral "#30344699";
        foreground = mkLiteral "#c6d0f5";
        selected = mkLiteral "#8caaee";
        active = mkLiteral "#a6d189";
        urgent = mkLiteral "#e78284";
        base00 = mkLiteral "#303446";
        base01 = mkLiteral "#292c3c";
        base02 = mkLiteral "#414559";
        base03 = mkLiteral "#51576d";
        base04 = mkLiteral "#626880";
        base05 = mkLiteral "#c6d0f5";
        base06 = mkLiteral "#f2d5cf";
        base07 = mkLiteral "#babbf1";
        base08 = mkLiteral "#e78284";
        base09 = mkLiteral "#ef9f76";
        base0A = mkLiteral "#e5c890";
        base0B = mkLiteral "#a6d189";
        base0C = mkLiteral "#81c8be";
        base0D = mkLiteral "#8caaee";
        base0E = mkLiteral "#ca9ee6";
        base0F = mkLiteral "#eebebe";
        border-color = mkLiteral "var(selected)";
        handle-color = mkLiteral "var(selected)";
        background-color = mkLiteral "var(background)";
        foreground-color = mkLiteral "var(foreground)";
        alternate-background = mkLiteral "var(background-alt)";
        normal-background = mkLiteral "var(background)";
        normal-foreground = mkLiteral "var(foreground)";
        urgent-background = mkLiteral "var(urgent)";
        urgent-foreground = mkLiteral "var(background)";
        active-background = mkLiteral "var(active)";
        active-foreground = mkLiteral "var(background)";
        selected-normal-background = mkLiteral "var(selected)";
        selected-normal-foreground = mkLiteral "var(background)";
        selected-urgent-background = mkLiteral "var(active)";
        selected-urgent-foreground = mkLiteral "var(background)";
        selected-active-background = mkLiteral "var(urgent)";
        selected-active-foreground = mkLiteral "var(background)";
        alternate-normal-background = mkLiteral "var(background)";
        alternate-normal-foreground = mkLiteral "var(foreground)";
        alternate-urgent-background = mkLiteral "var(urgent)";
        alternate-urgent-foreground = mkLiteral "var(background)";
        alternate-active-background = mkLiteral "var(active)";
        alternate-active-foreground = mkLiteral "var(background)";
      };

      window = {
        anchor = mkLiteral "center";
        background-color = mkLiteral "@background-color";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "10px";
        cursor = "default";
        enabled = mkLiteral "true";
        fullscreen = mkLiteral "false";
        location = mkLiteral "center";
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        transparency = "real";
        width = mkLiteral "1000px";
        x-offset = mkLiteral "0px";
        y-offset = mkLiteral "0px";
      };

      mainbox = {
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "0px 0px 0px 0px";
        children = map mkLiteral [ "inputbar" "message" "mode-switcher" "listview" ];
        enabled = mkLiteral "true";
        margin = mkLiteral "0px";
        padding = mkLiteral "20px";
        spacing = mkLiteral "0px";
      };

      inputbar = {
        background-color = mkLiteral "@alternate-background";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "10px";
        children = map mkLiteral [ "textbox-prompt-colon" "entry" ];
        enabled = mkLiteral "true";
        margin = mkLiteral "0px 0px 10px 0px";
        padding = mkLiteral "5px 10px";
        spacing = mkLiteral "10px";
        text-color = mkLiteral "@foreground-color";
      };

      prompt = {
        background-color = mkLiteral "inherit";
        enabled = mkLiteral "true";
        text-color = mkLiteral "inherit";
      };

      textbox-prompt-colon = {
        background-color = mkLiteral "inherit";
        enabled = mkLiteral "true";
        expand = mkLiteral "false";
        padding = mkLiteral "5px 0px";
        str = " ";
        text-color = mkLiteral "inherit";
      };

      entry = {
        background-color = mkLiteral "inherit";
        cursor = mkLiteral "text";
        enabled = mkLiteral "true";
        padding = mkLiteral "5px 0px";
        placeholder = "Search...";
        placeholder-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };

      num-filtered-rows = {
        background-color = mkLiteral "inherit";
        enabled = mkLiteral "true";
        expand = mkLiteral "false";
        text-color = mkLiteral "inherit";
      };

      textbox-num-sep = {
        background-color = mkLiteral "inherit";
        enabled = mkLiteral "true";
        expand = mkLiteral "false";
        str = " / ";
        text-color = mkLiteral "inherit";
      };

      num-rows = {
        background-color = mkLiteral "inherit";
        enabled = mkLiteral "true";
        expand = mkLiteral "false";
        text-color = mkLiteral "inherit";
      };


      case-indicator = {
        # expand = mkLiteral "false";
        # str = "Aa";
        background-color = mkLiteral "inherit";
        enabled = mkLiteral "true";
        text-color = mkLiteral "inherit";
      };

      listview = {
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px 2px 2px 2px";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "0px 0px 10px 10px";
        columns = mkLiteral "1";
        cursor = "default";
        cycle = mkLiteral "true";
        dynamic = mkLiteral "true";
        enabled = mkLiteral "true";
        fixed-columns = mkLiteral "true";
        fixed-height = mkLiteral "true";
        layout = mkLiteral "vertical";
        lines = mkLiteral "12";
        margin = mkLiteral "0px";
        padding = mkLiteral "10px";
        reverse = mkLiteral "false";
        scrollbar = mkLiteral "false";
        spacing = mkLiteral "5px";
        text-color = mkLiteral "@foreground-color";
      };

      scrollbar = {
        background-color = mkLiteral "@background-color";
        border-radius = mkLiteral "10px";
        handle-color = mkLiteral "@handle-color";
        handle-width = mkLiteral "4px";
      };

      element = {
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "6px";
        cursor = mkLiteral "pointer";
        enabled = mkLiteral "true";
        margin = mkLiteral "0px";
        padding = mkLiteral "6px";
        spacing = mkLiteral "10px";
        text-color = mkLiteral "@foreground-color";
      };

      "element normal.normal" = {
        background-color = mkLiteral "@normal-background";
        text-color = mkLiteral "@normal-foreground";
      };

      "element normal.urgent" = {
        background-color = mkLiteral "@urgent-background";
        text-color = mkLiteral "@urgent-foreground";
      };

      "element normal.active" = {
        background-color = mkLiteral "@active-background";
        text-color = mkLiteral "@active-foreground";
      };

      "element selected.normal" = {
        background-color = mkLiteral "@selected-normal-background";
        text-color = mkLiteral "@selected-normal-foreground";
      };

      "element selected.urgent" = {
        background-color = mkLiteral "@selected-urgent-background";
        text-color = mkLiteral "@selected-urgent-foreground";
      };

      "element selected.active" = {
        background-color = mkLiteral "@selected-active-background";
        text-color = mkLiteral "@selected-active-foreground";
      };

      "element alternate.normal" = {
        background-color = mkLiteral "@alternate-normal-background";
        text-color = mkLiteral "@alternate-normal-foreground";
      };

      "element alternate.urgent" = {
        background-color = mkLiteral "@alternate-urgent-background";
        text-color = mkLiteral "@alternate-urgent-foreground";
      };

      "element alternate.active" = {
        background-color = mkLiteral "@alternate-active-background";
        text-color = mkLiteral "@alternate-active-foreground";
      };

      element-icon = {
        background-color = mkLiteral "transparent";
        cursor = mkLiteral "inherit";
        size = mkLiteral "24px";
        text-color = mkLiteral "inherit";
      };

      element-text = {
        background-color = mkLiteral "transparent";
        cursor = mkLiteral "inherit";
        highlight = mkLiteral "inherit";
        horizontal-align = mkLiteral "0.0";
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };

      mode-switcher = {
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "0px";
        enabled = mkLiteral "true";
        expand = mkLiteral "false";
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        spacing = mkLiteral "0px";
        text-color = mkLiteral "@foreground-color";
      };

      button = {
        background-color = mkLiteral "@background-color";
        border = mkLiteral "0px 0px 2px 0px";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "10px 10px 0px 0px";
        cursor = mkLiteral "pointer";
        padding = mkLiteral "10px";
        text-color = mkLiteral "inherit";
      };

      "button selected" = {
        background-color = mkLiteral "@normal-background";
        border = mkLiteral "2px 2px 0px 2px";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "10px 10px 0px 0px";
        text-color = mkLiteral "@normal-foreground";
      };

      message = {
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "0px 0px 0px 0px";
        enabled = mkLiteral "true";
        margin = mkLiteral "0px 0px 10px 0px";
        padding = mkLiteral "0px";
        text-color = mkLiteral "@foreground-color";
      };

      textbox = {
        background-color = mkLiteral "@alternate-background";
        blink = mkLiteral "true";
        border = mkLiteral "0px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "10px";
        highlight = mkLiteral "none";
        horizontal-align = mkLiteral "0.0";
        markup = mkLiteral "true";
        padding = mkLiteral "10px";
        placeholder-color = mkLiteral "@foreground-color";
        text-color = mkLiteral "@foreground-color";
        vertical-align = mkLiteral "0.5";
      };

      error-message = {
        background-color = mkLiteral "@background-color";
        border = mkLiteral "2px solid";
        border-color = mkLiteral "@border-color";
        border-radius = mkLiteral "10px";
        padding = mkLiteral "10px";
        text-color = mkLiteral "@foreground-color";
      };
    };
    extraConfig = {
      font = "Fira Code 12";

      modi = "drun,emoji,ssh,run,filebrowser,window,keys";
      show-icons = mkLiteral "true";
      display-drun = "  Apps";
      display-run = "  Run";
      display-filebrowser = "  Files";
      display-window = "  Windows";
      display-ssh = "  SSH";
      display-emoji = "  Emoji";
      display-keys = "  Keys";

      window-format = "{w} · {c} · {t}";

      # SSH Settings
      ssh-client = "ssh";
      ssh-command = "{terminal} -e {ssh-client} {host} [-p {port}]";
      parse-hosts = mkLiteral "true";
      parse-known-hosts = mkLiteral "true";

      # Drun Settings
      drun-categories = "";
      drun-match-fields = "name,generic,exec,categories,keywords";
      drun-display-format = "{name} [<span weight='light' size='small'><i>({generic})</i></span>]";
      drun-show-actions = mkLiteral "false";
      drun-url-launcher = "xdg-open";
      drun-use-desktop-cache = mkLiteral "false";
      drun-reload-desktop-cache = mkLiteral "false";

      # kb-mode-next = "Shift+Right,Tab";
      # kb-mode-previous = "Shift+Left,ISO_Left_Tab";

      # kb-primary-paste = "Control+V,Shift+Insert";
      # kb-secondary-paste = "Control+v,Insert";
      # case-sensitive = mkLiteral "false";
      # cycle = mkLiteral "true";
      # # filter = "";
      # scroll-method = mkLiteral "0";
      # normalize-match = mkLiteral "true";
      # icon-theme = "Papirus";
      # steal-focus = mkLiteral "false";
      # matching = "normal";
      # tokenize = mkLiteral "true";

      # drun-categories = "";
      # drun-match-fields = "name,generic,exec,categories,keywords";
      # drun-show-actions = mkLiteral "false";
      # drun-url-launcher = "xdg-open";
      # drun-use-desktop-cache = mkLiteral "false";
      # drun-reload-desktop-cache = mkLiteral "false";
    };
  };
}