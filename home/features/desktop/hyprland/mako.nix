{
  config,
  lib,
  pkgs,
  ...
}:

with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

{
  services.mako =
  let

    font = "${monospace.name}";
    background-default = "${base00}";
    border = "${base0D}";
    progress = "${base01}";
    text-color = "${base0A}";
    background-low = "${base06}";
    text-color-low = "${base0A}";
    backgroud-high = "${base0F}";
    test-color-high = "${base06}";
    opacity = lib.toHexString (((builtins.ceil (config.stylix.opacity.popups * 100)) * 255) / 100);
  in
  {
    enable = true;
    package = pkgs.mako;
    actions = true;
    anchor = "top-center";
    backgroundColor = "${background-default}${opacity}";
    borderColor = "${border}";
    borderRadius = 0;
    borderSize = 2;
    defaultTimeout = 2000;
    extraConfig = ''
      [urgency=low]
      background-color = "${background-low}${opacity}"
      border-color = "${border}"
      text-color = "${text-color-low}"

      [urgency=high]
      background-color = "${backgroud-high}${opacity}"
      border-color = "${border}"
      text-color = "${test-color-high}"
    '';
    font = "${font} 12";
    format = "<b>%s</b>\\n%b";
    groupBy = null;
    height = 500;
    icons = true;
    ignoreTimeout = false;
    layer = "overlay";
    margin = "10";
    markup = true;
    maxIconSize = 64;
    maxVisible = 5;
    padding = "10,20";
    progressColor = "over ${progress}";
    sort = "-time";
    textColor = "${text-color}";
    width = 800;
  };
}
