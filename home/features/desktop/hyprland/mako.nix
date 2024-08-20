{
  pkgs,
  ...
}:

{
  services.mako = {
    enable = true;
    package = pkgs.mako;
    actions = true;
    anchor = "center";
    borderRadius = 0;
    borderSize = 2;
    defaultTimeout = 1200;
    # extraConfig = "";
    # font = "";
    # format = "";
    groupBy = null;
    height = 150;
    ignoreTimeout = false;
    layer = "overlay";
    margin = "10";
    padding = "10,20";
    sort = "-time";
    width = 400;
  };
}
