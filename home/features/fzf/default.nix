# TODO add config for fzf
# A command-line fuzzy finder
{
  pkgs,
  ...
}:
# let
#   inherit (config.colorscheme) palette;
# in
{
# source = pkgs.writeShellScript "pv.sh" ''
  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
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
  };

  home.packages = with pkgs; [
    fd
  ];
}
