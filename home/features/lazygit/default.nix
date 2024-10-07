# Configs https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
{
  config,
  pkgs,
  ...
}:

{
  programs = {
    lazygit = {
      enable = true;
      package = pkgs.lazygit;
      settings = {
        git = {
            log.order = "default";
            fetchAll = false;
        };
        theme = {
          activeBorderColor = [
            "${config.lib.stylix.colors.withHashtag.base07}"
            "bold"
          ];
          inactiveBorderColor = [
            "${config.lib.stylix.colors.withHashtag.base04}"
          ];
          optionsTextColor = [
            "${config.lib.stylix.colors.withHashtag.base0D}"
          ];
          selectedLineBgColor = [
            "${config.lib.stylix.colors.withHashtag.base02}"
          ];
          cherryPickedCommitBgColor = [
            "${config.lib.stylix.colors.withHashtag.base03}"
          ];
          cherryPickedCommitFgColor = [
            "${config.lib.stylix.colors.withHashtag.base07}"
          ];
          unstagedChangesColor = [
            "${config.lib.stylix.colors.withHashtag.base08}"
          ];
          defaultFgColor = [
            "${config.lib.stylix.colors.withHashtag.base05}"
          ];
          searchingActiveBorderColor = [
            "${config.lib.stylix.colors.withHashtag.base0A}"
          ];
        };
        authorColors = {
          "*" = "${config.lib.stylix.colors.withHashtag.base07}";
        };
      };
    };
  };
  home.shellAliases = {
    lg = "lazygit";
  };
}