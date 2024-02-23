# TODO add config for fzf
# A command-line fuzzy finder
{
  config,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) palette;
in
{
# source = pkgs.writeShellScript "pv.sh" ''
  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
    colors = {
      "fg" = "#${palette.base06}";
      "bg" = "#${palette.base03}";
      "hl" = "#${palette.base0B}";
      "fg+" = "#${palette.base04}";
      "bg+" = "#${palette.base00}";
      "hl+" = "#${palette.base04}";
      "pointer" = "#${palette.base08}";
      "info" = "#${palette.base03}";
      "spinner" = "#${palette.base03}";
      "header" = "#${palette.base03}";
      "prompt" = "#${palette.base0D}";
      "marker" = "#${palette.base0A}";
    };
    defaultCommand = "find . -type f ! -path '.git'";
    defaultOptions = [
      "--preview='pistol {}'"
      "--height=40%"
      "--border"
    ];
    fileWidgetCommand = "find . -type f ! -path '.git'";
    fileWidgetOptions = [
      "--preview 'bat --color=always {}'"
      # "--preview 'head {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
    # changeDirWidgetCommand = "fd --type d";
    # changeDirWidgetOptions = [
    #   "--preview 'tree -C {} | head -200'"
    #   # "--preview='ls -l {}'"
    # ];
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    fd
  ];
}
