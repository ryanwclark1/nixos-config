{
  pkgs,
  ...
}:

{
  imports = [
    ./basic-binds.nix
    ./cliphist.nix
    ./hyprbars.nix
    ./hyprland.nix
    ./hyprlock
    ./hypridle
    ./mako.nix
    ./rofi.nix
    ./waybar.nix
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