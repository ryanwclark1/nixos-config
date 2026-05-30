# An interactive cheatsheet tool for the command-line
{
  config,
  lib,
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
  programs.navi = {
    enable = true;
    package = pkgs.navi;
    enableBashIntegration = lib.mkIf config.programs.bash.enable false;
    enableFishIntegration = lib.mkIf config.programs.fish.enable false;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable false;
    settings = {
      finder = {
        command = "fzf";
      };
      client = {
        tealdeer = true;
      };
      shell = {
        command = "bash";
      };
      # style = {
      #   tag ={
      #     color = "";
      #   };
      #   comment ={
      #     color = "";
      #   };
      #   snippet ={
      #     color = "";
      #   };
      # };
    };
  };
}
