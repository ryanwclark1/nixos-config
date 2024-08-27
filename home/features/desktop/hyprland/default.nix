{
  pkgs,
  ...
}:

{
  imports = [
    ./basic-binds.nix
    ./cliphist
    ./dunst
    ./hyprbars.nix
    ./hyprland.nix
    ./hyprlock
    ./hypridle
    ./mako.nix
    ./rofi
    ./waybar
    # ./eww
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
    ];
  };
}