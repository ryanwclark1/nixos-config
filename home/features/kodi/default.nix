{
  pkgs,
  ...
}:

{
  porgrams.kodi = {
    enable = true;
    package = pkgs.kodi;
    # addonSettings = [
    #   {
    #     name = "plugin.video.youtube";
    #     enable = true;
    #   }
    # ];
  };
}