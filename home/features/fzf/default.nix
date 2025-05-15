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
    pkgs.file
    (pkgs.writeScriptBin "bluetoothz" (builtins.readFile ./scripts/bluetoothz))
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
    (pkgs.writeScriptBin "wifiz" (builtins.readFile ./scripts/wifiz))
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
        "-p 80%,60%"
      ];
    };
    changeDirWidgetCommand = "fd --type directory --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --level=2 --color=always {} | head -100'"
    ];
    colors = {
      bg = "-1";
      "bg+" = "#${base02}";
      fg = "#${base05}";
      "fg+" = "#${base05}";
      header = "#${base08}";
      hl = "#${base08}";
      "hl+" = "#${base08}";
      info = "#${base0E}";
      marker = "#${base07}";
      pointer = "#${base06}";
      spinner = "#${base06}";
      prompt = "#${base0E}";
      selected-bg = "#${base03}";
      border = "#${base0D}";
      label = "#${base05}";
    };
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--bind=ctrl-j:down,ctrl-k:up,ctrl-h:toggle-preview"
      "--preview='([[ -d {} ]] && eza --tree --level=2 --color=always {} | head -200) || (file {} | grep -q binary && echo {} is binary) || bat --style=numbers --color=always --line-range=:500 {}'"
      "--color=bg:-1,bg+:#${base02},border:#${base0D},fg:#${base05},fg+:#${base05},header:#${base08},hl:#${base08},hl+:#${base08},info:#${base0E},label:#${base05},marker:#${base07},pointer:#${base06},prompt:#${base0E},selected-bg:#${base03},spinner:#${base06}"
    ];
    fileWidgetCommand = "fd --type file --follow --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    fileWidgetOptions = [
      "--preview '([[ -d {} ]] && eza --tree --level=2 --color=always {} | head -100) || (file {} | grep -q binary && echo {} is binary) || bat --style=numbers --color=always --line-range=:500 {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
      "--preview 'echo {}'"
      "--preview-window=up:3:hidden:wrap"
      "--bind ctrl-h:toggle-preview"
    ];
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

}
