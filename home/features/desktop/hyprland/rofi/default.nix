{
  config,
  pkgs,
  ...
}:

# TODO: Fix ssh functionality
{
  imports = [
    ./scripts
  ];

  home.file = {
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
    terminal = "ghostty";
    pass = {
      enable = true;
      package = pkgs.rofi-pass-wayland;
      stores = [
        "${config.home.homeDirectory}/.local/share/keyrings"
      ];
    };
    theme =
    let
    # Use `mkLiteral` for string-like values that should show without
    # quotes, e.g.:
    # {
    #   foo = "abc"; =&gt; foo: "abc";
    #   bar = mkLiteral "abc"; =&gt; bar: abc;
    # };
    inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        background-color = mkLiteral "var(background)";
        foreground-color = mkLiteral "var(foreground)";
        border-color = mkLiteral "var(selected);";
        width = 512;
      };

      "#inputbar" = {
        children = map mkLiteral [ "prompt" "entry" ];
      };

      "#textbox-prompt-colon" = {
        expand = false;
        str = ":";
        margin = mkLiteral "0px 0.3em 0em 0em";
        text-color = mkLiteral "@foreground-color";
      };
      extraConfig = ''
        /*****----- Global Properties -----*****/
        @import                          "style/shared/colors.rasi"
        @import                          "style/shared/fonts.rasi"
      '';
    };
  };
}