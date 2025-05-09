{
  lib,
  pkgs,
  ...
}:

{
  # xfce not desktop allows preference to be saved
  programs.xconf.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce;
    [
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-volman
      thunar-vcs-plugin
    ];
  };

  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer
  ];
  # Thumbnail support for images
  services.tumbler.enable = lib.mkDefault true;
  # Mount, trash, and other functionalities
  services.gvfs.enable = lib.mkDefault true;
}
