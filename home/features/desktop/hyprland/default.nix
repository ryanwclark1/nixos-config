{
  pkgs,
  ...
}:

{
  imports = [
    ./basic-binds.nix
    ./cliphist
    ./dunst
    ./eww
    ./hyprbars.nix
    ./hypridle
    ./hypr
    ./hyprlock
    ./mako.nix
    ./rofi
    ./waybar
    # ./wofi.nix
    # ./variables.nix
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
    ];
  };
}