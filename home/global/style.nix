# Docs: https://stylix.danth.me/
{
  pkgs,
  ...
}:
let
  currentScheme = "catppuccin-frappe";
in
# In home-manager
{
  home.packages = with pkgs; [
    base16-schemes
  ];
  stylix = {
    enable = true;
    autoEnable = false;
    image = ../../hosts/common/wallpaper/FormulaOne_Vettel_2.jpg;
    imageScalingMode = "fill";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };
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
        package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
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
    opacity = {
      applications = 0.95;
      desktop = 0.95;
      popups = 0.80;
      terminal = 0.85;
    };
    targets = {
      alacritty.enable = true;
      bat.enable = true;
      btop.enable = true;
      firefox = {
        enable = true;
        # profileNames = ["default"];
      };
      fish.enable = true;
      fzf.enable = true;
      gedit.enable = true;
      gitui.enable = true;
      gnome.enable = true;
      gtk = {
        enable = true;
        # extraCss = ''
        #   @import url("file://${pkgs.stylix}/share/themes/${currentScheme}.css");
        # '';
      };
      hyprland.enable = true;
      hyprpaper.enable = true;
      k9s.enable = true;
      kde.enable = true;
      kitty = {
        enable = true;
        # variant256Colors = true;
      };
      lazygit.enable = true;
      mako.enable = false;
      neovim = {
        enable = true;
        transparentBackground = {
          main = true;
          signColumn = true;
        };
      };
      nixvim = {
        enable = true;
        transparentBackground = {
          main = true;
          signColumn = true;
        };
      };
      qutebrowser.enable = true;
      rofi.enable = false;
      vscode.enable = false;
      waybar = {
        enable = false;
        enableCenterBackColors = false;
        enableLeftBackColors = false;
        enableRightBackColors = false;
      };
      wofi.enable = false;
      yazi.enable = true;
      zathura.enable = true;
      zellij.enable = true;
    };
  };
}