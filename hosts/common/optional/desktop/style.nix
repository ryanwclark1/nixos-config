{
  pkgs,
  ...
}:
let
  currentScheme = "catppuccin-frappe";
in
{
  imports = [
    ../tools/fonts.nix
  ];

  environment.systemPackages = with pkgs; [
    base16-schemes
  ];

  stylix = {
    enable = true;
    autoEnable = false;
    imageScalingMode = "fill";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    polarity = "either";
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
        package = pkgs.nerd-fonts.ubuntu-mono;
        name = "UbuntuMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
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
      # autoImport = false;
    };
    opacity = {
      applications = 0.80;
      desktop = 0.90;
      popups = 0.80;
      terminal = 0.80;
    };
    targets = {
      console.enable = true;
      gnome.enable = false;
      grub = {
        enable = false;
        useWallpaper = true;
      };
      gtk.enable = false;
      nixos-icons.enable = true;
      qt.enable = false;
      # nixvim = {
      #   enable = true;
      #   transparentBackground = {
      #     main = true;
      #     signColumn = true;
      #   };
      # };
      plymouth.enable = false;
    };
  };
}
