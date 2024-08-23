{
  pkgs,
  ...
}:
let
  currentScheme = "nord";
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
    # image = "~/Pictures/wallpaper/FormulaOne_Vettel_2.jpg";
    imageScalingMode = "fill";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
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
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
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
      mako.enable = true;
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
      vscode.enable = false;
      waybar = {
        enable = true;
        enableCenterBackColors = false;
        enableLeftBackColors = true;
        enableRightBackColors = true;
      };
      wofi.enable = true;
      yazi.enable = true;
      zathura.enable = true;
      zellij.enable = true;
    };
  };
}