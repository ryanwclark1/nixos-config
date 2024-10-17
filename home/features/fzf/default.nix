# TODO add config for fzf
# A command-line fuzzy finder
{
  lib,
  config,
  pkgs,
  ...
}:

{
  home.packages = [
    (pkgs.writeScriptBin "fzf-git" (builtins.readFile ./fzf-git.sh))
    (pkgs.writeScriptBin "rgf" (builtins.readFile ./rgf.sh))
    (pkgs.writeScriptBin "sysz" (builtins.readFile ./sysz.sh))
  ];

  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
    tmux = {
      enableShellIntegration = lib.mkIf config.programs.tmux.enable true;
      shellIntegrationOptions = [
        "-d 50%"
      ];
    };
    changeDirWidgetCommand = "fd --type directory --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions =
    [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];
    colors = {
      "bg+" = "#414559";
      # bg = "#303446";
      spinner = "#f2d5cf";
      hl = "#e78284";
      fg = "#c6d0f5";
      header = "#e78284";
      info = "#ca9ee6";
      pointer = "#f2d5cf";
      marker = "#babbf1";
      "fg+" = "#c6d0f5";
      prompt = "#ca9ee6";
      "hl+" = "#e78284";
      selected-bg = "#51576d";
    };
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat --style=numbers --color=always --line-range=:500 {}; fi'"
    ];
    fileWidgetCommand = "fd --type file --follow --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range=:500 {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

  programs.bash.bashrcExtra = ''
    source fzf-git
  '';

  programs.zsh.initExtra = ''
    source fzf-git
  '';
}
