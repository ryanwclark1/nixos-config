# TODO add config for fzf
# A command-line fuzzy finder
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    fzf-git-sh
  ];

  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
    changeDirWidgetCommand = "fd --type directory";
    changeDirWidgetOptions =
    [
      "--preview 'tree -C {} | head -200'"
    ];
    defaultCommand = "fd --type file --exclude .git";
    defaultOptions = [
      # "--preview='pistol {}'"
      "--height=40%"
      "--layout=reverse"
      "--info=inline"
      "--border"
      "--margin=1"
      "--padding=1"
      "--border"
    ];
    fileWidgetCommand = "fd --type file --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always {}'"
      # "--preview 'head {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

}
