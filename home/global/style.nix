# Docs: https://stylix.danth.me/
{
  lib,
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
    enable = lib.mkDefault true;
    autoEnable = lib.mkDefault false;
    image = ../../hosts/common/wallpaper/FormulaOne_Vettel_2.jpg;
    imageScalingMode = lib.mkDefault "fill";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    cursor = {
      package = lib.mkDefault pkgs.bibata-cursors;
      name = lib.mkDefault "Bibata-Modern-Classic";
      size = lib.mkDefault 16;
    };
    iconTheme = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.adwaita-icon-theme;
    };
    fonts = {
      serif = {
        package = lib.mkDefault pkgs.dejavu_fonts;
        name = lib.mkDefault "DejaVu Serif";
      };
      sansSerif = {
        package = lib.mkDefault pkgs.dejavu_fonts;
        name = lib.mkDefault "DejaVu Sans";
      };
      monospace = {
        package = lib.mkDefault pkgs.nerd-fonts.ubuntu-mono;
        name = lib.mkDefault "UbuntuMono Nerd Font";
      };
      emoji = {
        package = lib.mkDefault pkgs.noto-fonts-emoji;
        name = lib.mkDefault "Noto Color Emoji";
      };
      sizes = {
        applications = lib.mkDefault 12;
        desktop = lib.mkDefault 10;
        popups = lib.mkDefault 10;
        terminal = lib.mkDefault 12;
      };
    };
    opacity = {
      applications = lib.mkDefault 0.80;
      desktop = lib.mkDefault 0.90;
      popups = lib.mkDefault 0.80;
      terminal = lib.mkDefault 0.80;
    };
    targets = {
      alacritty.enable = lib.mkDefault false;
      bat.enable = lib.mkDefault false;
      btop.enable = lib.mkDefault false;
      firefox = {
        enable = lib.mkDefault false;
        # profileNames = ["default"];
      };
      fish.enable = lib.mkDefault false;
      fzf.enable = lib.mkDefault false;
      gedit.enable = lib.mkDefault false;
      gitui.enable = lib.mkDefault false;
      gnome.enable = lib.mkDefault false;
      gtk = {
        enable = lib.mkDefault false;
        # extraCss = ''
        #   @import url("file://${pkgs.stylix}/share/themes/${currentScheme}.css");
        # '';
      };
      hyprland.enable = lib.mkDefault false;
      hyprpaper.enable = lib.mkDefault false;
      k9s.enable = lib.mkDefault false;
      kde.enable = lib.mkDefault false;
      kitty = {
        enable = lib.mkDefault false;
        variant256Colors = lib.mkDefault false;
      };
      lazygit.enable = lib.mkDefault false;
      mako.enable = lib.mkDefault false;
      neovim = {
        enable = lib.mkDefault false;
        transparentBackground = {
          main =lib.mkDefault  false;
          signColumn = lib.mkDefault false;
        };
      };
      nixvim = {
        enable = lib.mkDefault false;
        transparentBackground = {
          main = lib.mkDefault false;
          signColumn = lib.mkDefault false;
        };
      };
      qutebrowser.enable = lib.mkDefault false;
      rofi.enable = lib.mkDefault false;
      vscode.enable = lib.mkDefault false;
      waybar = {
        enable = lib.mkDefault false;
        enableCenterBackColors = lib.mkDefault false;
        enableLeftBackColors = lib.mkDefault false;
        enableRightBackColors = lib.mkDefault false;
      };
      wofi.enable = lib.mkDefault false;
      xfce.enable = lib.mkDefault false;
      xresources.enable = lib.mkDefault false;
      yazi.enable = lib.mkDefault false;
      zathura.enable = lib.mkDefault false;
      zellij.enable = lib.mkDefault false;
    };
  };
}