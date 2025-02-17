# TODO add config for fzf
# A command-line fuzzy finder
{
  lib,
  config,
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
in
{
  home.packages = [
    (pkgs.writeScriptBin "dkr" (builtins.readFile ./scripts/dkr))
    (pkgs.writeScriptBin "fv" (builtins.readFile ./scripts/fv)) 
    (pkgs.writeScriptBin "fzf-git" (builtins.readFile ./scripts/fzf-git))
    (pkgs.writeScriptBin "fzmv" (builtins.readFile ./scripts/fzmv))
    (pkgs.writeScriptBin "fztop" (builtins.readFile ./scripts/fztop))
    (pkgs.writeScriptBin "gitup" (builtins.readFile ./scripts/gitup))
    (pkgs.writeScriptBin "igr" (builtins.readFile ./scripts/igr))
    (pkgs.writeScriptBin "rgf" (builtins.readFile ./scripts/rgf))
    (pkgs.writeScriptBin "sshget" (builtins.readFile ./scripts/sshget))
    (pkgs.writeScriptBin "sysz" (builtins.readFile ./scripts/sysz))
    (pkgs.writeScriptBin "wifiz" (builtins.readFile ./scripts/wifi))
  ];

  # Copy these scripts to the user's home directory for dotfiles repo
  home.file.".config/scripts" = {
    source = ./scripts;
    recursive = true;
  };

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
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];
    colors = {
      "bg+" = "#${base02}";
      bg = "#${base00}";
      spinner = "#${base06}";
      hl = "#${base08}";
      fg = "#${base05}";
      header = "#${base08}";
      info = "#${base0E}";
      pointer = "#${base06}";
      marker = "#${base07}";
      "fg+" = "#${base05}";
      prompt = "#${base0E}";
      "hl+" = "#${base08}";
      selected-bg = "#${base03}";
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

}
