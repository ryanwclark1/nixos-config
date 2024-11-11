{
  pkgs,
  ...
}:

{
  programs.kodi = {
    enable = true;
    package = pkgs.kodi-wayland;
    # addonSettings = [
    #   {
    #     name = "plugin.video.youtube";
    #     enable = true;
    #   }
    # ];
  };
}