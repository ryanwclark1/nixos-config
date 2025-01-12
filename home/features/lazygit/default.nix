# Configs https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
{
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
            "#ca9ee6"
            "bold"
          ];
          inactiveBorderColor = [
            "#a5adce"
          ];
          optionsTextColor = [
            "#8caaee"
          ];
          selectedLineBgColor = [
            "#414559"
          ];
          cherryPickedCommitBgColor = [
            "#51576d"
          ];
          cherryPickedCommitFgColor = [
            "#ca9ee6"
          ];
          unstagedChangesColor = [
            "#e78284}"
          ];
          defaultFgColor = [
            "#c6d0f5"
          ];
          searchingActiveBorderColor = [
            "#e5c890"
          ];
        };
        authorColors = {
          "*" = "#babbf1";
        };
      };
    };
  };
  home.shellAliases = {
    lg = "lazygit";
  };
}