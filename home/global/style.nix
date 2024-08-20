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
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentScheme}.yaml";
    image = ../../hosts/common/wallpaper/FormulaOne_Vettel_2.jpg;
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