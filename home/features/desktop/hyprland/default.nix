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
    ./mako.nix
    ./rofi.nix
    ./swayidle.nix
    ./swaylock.nix
    ./waybar.nix
    ./wofi.nix
  ];

  home.packages = with pkgs; [
    wf-recorder
    wl-clipboard
    swaybg
    # inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    hyprpicker
    grim
    slurp
    wl-clip-persist
    wf-recorder
  ];
}