{
  pkgs,
  ...
}:
let
  currentScheme = "nord";
in
# In home-manager
{
  stylix = {
    enable = false;
    autoEnable = false;
    base16Schemes = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    image = ../wallpaper/FormulaOne_Vettel_2.jpg;
    imageScalingMode = "fill";
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
      git.enable = true;
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
      kitty.enable = true;
      lazygit.enable = true;
      mako.enable = true;
      vscode.enable = false;
      waybar = {
        enable = true;
        enableCenterBackColors = true;
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