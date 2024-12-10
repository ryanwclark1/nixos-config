{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.mako =
  let
    opacity = lib.toHexString (((builtins.ceil (config.stylix.opacity.popups * 100)) * 255) / 100);
  in
  {
    enable = true;
    package = pkgs.mako;
    actions = true;
    anchor = "top-center";
    backgroundColor = "${config.lib.stylix.colors.withHashtag.base00}${opacity}";
    borderColor = "${config.lib.stylix.colors.withHashtag.base0D}";
    borderRadius = 0;
    borderSize = 2;
    defaultTimeout = 2000;
    extraConfig = ''
      [urgency=low]
      background-color = "${config.lib.stylix.colors.withHashtag.base06}${opacity}"
      border-color = "${config.lib.stylix.colors.withHashtag.base0D}"
      text-color = "${config.lib.stylix.colors.withHashtag.base0A}"

      [urgency=high]
      background-color = "${config.lib.stylix.colors.withHashtag.base0F}${opacity}"
      border-color = "${config.lib.stylix.colors.withHashtag.base0D}"
      text-color = "${config.lib.stylix.colors.withHashtag.base06}"
    '';
    font = "${config.stylix.fonts.monospace.name} 12";
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
    progressColor = "over ${config.lib.stylix.colors.withHashtag.base01}";
    sort = "-time";
    textColor = "${config.lib.stylix.colors.withHashtag.base0A}";
    width = 800;
  };
}
