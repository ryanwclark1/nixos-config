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
    ./hyprlock.nix
    ./mako.nix
    # ./swayidle.nix
    # ./swaylock.nix
    ./waybar.nix
    ./wofi.nix
    # ./variables.nix
  ];

  home = {
    # file.".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    # file.".emoji".source = ./config/emoji;
    file."Pictures/wallpapers" = {
      source = ../../../../hosts/common/wallpaper;
      recursive = true;
    };

    packages = with pkgs; [
      wf-recorder
      wl-clipboard
      # swaybg
      # inputs.hypr-contrib.packages.${pkgs.system}.grimblast
      # hyprpicker
      # grim
      # slurp
      # wl-clip-persist
    ];
  };
}