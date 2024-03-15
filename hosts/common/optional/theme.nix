{
  config,
  pkgs,
  ...
}:
let
  currentScheme = "nord";
in
{
  stylix = {
    image = ../wallpaper/FormulaOne_Vettel_1.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sansSerif = {
        package = config.stylix.fonts.serif.package;
        name = "DejaVu Sans";
      };
      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 12;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };
    homeManagerIntegration = {
      followSystem = true;
      autoImport = true;
    };
    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.8;
    };
    polarity = "dark";
    targets = {
      grub.useImage = true;
    };
  };
  fonts = {
    fontconfig = {
      enable = true;
      allowBitmaps = true;
      antialias = true;
    };

    packages = with pkgs; [
      nerdfonts
      powerline-fonts
      powerline-symbols
    ];
  };
}