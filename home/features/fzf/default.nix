# TODO add config for fzf
# A command-line fuzzy finder
{
  pkgs,
  ...
}:

{
  programs.fzf = {
    enable = true;
    colors = {
      "fg" = "#D8DEE9";
      "bg" = "#2E3440";
      "hl" = "#A3BE8C";
      "fg+" = "#D8DEE9";
      "bg+" = "#434C5E";
      "hl+" = "#A3BE8C";
      "pointer" = "#BF616A";
      "info" = "#4C566A";
      "spinner" = "#4C566A";
      "header" = "#4C566A";
      "prompt" = "#81A1C1";
      "marker" = "#EBCB8B";
    };
    changeDirWidgetCommand = "fd --type d";
    changeDirWidgetOptions = [
      "--preview 'tree -C {} | head -200'"
      # "--preview='ls -l {}'"
    ];
    defaultCommand = "fd --type f";
    defaultOptions = [
      "--preview='pistol {}'"
      "--height=40%"
      "--border"
    ];
    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = [
      "--preview 'bat --color=always {}'"
      # "--preview 'head {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    skim
  ];
}
