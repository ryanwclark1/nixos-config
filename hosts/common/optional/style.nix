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
    enable = false;
    autoEnable = false;
    image = ../wallpaper/FormulaOne_Vettel_2.jpg;
    imageScalingMode = "fill";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    polarity = "dark";
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
      followSystem = false;
      autoImport = false;
    };
    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.85;
    };
    targets = {
      gnome.enable = true;
      grub = {
        enable = true;
        useImage = true;
      };
      nixos-icons.enable = true;
      gtk.enable = true;
      plymouth.enable = false;
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