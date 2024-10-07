# TODO add config for fzf
# A command-line fuzzy finder
{
  lib,
  config,
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
    tmux = {
      enableShellIntegration = lib.mkIf config.programs.tmux.enable true;
      # fzf-tmux --help
      shellIntegrationOptions = [
        "-d 50%"
      ];
    };
    changeDirWidgetCommand = "fd --type directory --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions =
    [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    defaultOptions = [
      # "--preview='pistol {}'"
      # "--ansi"
      # "--height=40%"
      # "--layout=reverse"
      # "--info=inline"
      # "--border"
      # "--margin=1"
      # "--padding=1"
      # "--border"
    ];
    fileWidgetCommand = "fd --type file --follow --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --line-range=:500 {}'"
      # "--preview 'head {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

}
