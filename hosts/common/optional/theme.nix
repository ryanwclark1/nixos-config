{
  pkgs,
  ...
}:

{
  stylix = {
    image = ../wallpaper/FormulaOne_Vettel_1.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      monospace = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans Mono";
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
      background = 0.9;
      applications = 0.9;
      oppacity = 0.9;
      terminal = 0.8;
    };
    polarity = "dark";
    # targets = {
    #   chromium.enable = true;
    #   console.enable = true;
    #   fish.enable = true;
    #   gnome.enable = true;
    #   grub.useImage = true;
    #   gtk.enable = true;
    # };
  };
}