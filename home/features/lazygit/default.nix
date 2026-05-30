# Configs https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
{
  config,
  pkgs,
  ...
}:
let
  inherit (config.theme.colors)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
    base10
    base11
    base12
    base13
    base14
    base15
    base16
    base17
    ;
in
{
  programs.lazygit = {
    enable = true;
    package = pkgs.lazygit;
    settings = {
      git = {
        log.order = "default";
        fetchAll = false;
      };
      theme = {
        activeBorderColor = [
          "#${base0E}"
          "bold"
        ];
        inactiveBorderColor = [
          "#${base05}"
        ];
        optionsTextColor = [
          "#${base0D}"
        ];
        selectedLineBgColor = [
          "#${base02}"
        ];
        cherryPickedCommitBgColor = [
          "#${base03}"
        ];
        cherryPickedCommitFgColor = [
          "#${base0E}"
        ];
        unstagedChangesColor = [
          "#${base08}"
        ];
        defaultFgColor = [
          "#${base05}"
        ];
        searchingActiveBorderColor = [
          "#${base0A}"
        ];
      };
      authorColors = {
        "*" = "#${base07}";
      };

    };
  };
  home.shellAliases = {
    lg = "lazygit";
  };
}
