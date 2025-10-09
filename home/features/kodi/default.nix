{
  pkgs,
  ...
}:

{
  programs.kodi = {
    enable = false;
    # addonSettings = [
    #   {
    #     name = "plugin.video.youtube";
    #     enable = true;
    #   }
    # ];
  };
}
