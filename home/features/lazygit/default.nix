# Configs https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
{
  pkgs,
  ...
}:
let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
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
