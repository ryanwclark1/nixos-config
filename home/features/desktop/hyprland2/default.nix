{
  ...
}:

{
  imports = [
    ./basic-binds.nix
    ./hyprland.nix
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
    # file.".config/hypr" = {
    #   source = ./config/hyprland;
    #   recursive = true;
    # };
  };

}