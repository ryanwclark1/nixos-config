{
  pkgs,
  ...
}:

{
  imports = [
    # ./hyprland-vnc.nix
    ./basic-binds.nix
    ./hyprbars.nix
    ./hyprland.nix
    ./rofi.nix
    ./waybar.nix
  ];

    home = {
    file.".config/pipewire/pipewire.conf".source = ./config/pipewire/pipewire.conf;
    file.".emoji".source = ./config/emoji;
    file."Pictures/Wallpapers" = {
      source = ../../../../hosts/common/wallpaper;
      recursive = true;
    };
    file.".config/rofi" = {
      source = ./config/rofi;
      recursive = true;
    };
    file.".config/swaync" = {
      source = ./config/swaync;
      recursive = true;
    };
    file.".config/hypr" = {
      source = ./config/hyprland;
      recursive = true;
    };
  };

  home.packages = with pkgs; [
    audacity
    cmatrix
    gnome.file-roller
    grim
    libnotify
    libvirt
    material-icons
    mimeo # Mimetype handler
    noto-fonts-color-emoji
    pavucontrol
    polkit_gnome
    slurp
    spotify
    swaynotificationcenter
    swww
    symbola
    waypipe
    wf-recorder
    wl-clipboard
    wl-mirror
    xdg-utils
    ydotool
    # Import Scripts
    (import ./scripts/emopicker9000.nix { inherit pkgs; })
    (import ./scripts/task-waybar.nix { inherit pkgs; })
    (import ./scripts/wallsetter.nix { inherit pkgs; })
  ];

}
