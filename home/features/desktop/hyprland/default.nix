{
  pkgs,
  ...
}:

{
  imports = [
    ./cliphist
    ./dunst
    ./eww
    ./hypridle
    ./hypr
    ./hyprlock
    # ./mako
    ./rofi
    ./swaync
    ./waybar
    ./imv.nix
    # ./wofi.nix
  ];

  home = {
    file."Pictures/wallpapers" = {
      source = ../../../../hosts/common/wallpaper;
      recursive = true;
    };

    packages = with pkgs; [
      wf-recorder
      wl-clipboard
      grim
      slurp
      grimblast
      hyprpicker
      swww
      yad
    ];
  };
}