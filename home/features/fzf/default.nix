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
    pkgs.wl-clipboard  # For clipboard integration in fzf
    (pkgs.writeScriptBin "bluetoothz" (builtins.readFile ./scripts/bluetoothz.sh))
    (pkgs.writeScriptBin "dkr" (builtins.readFile ./scripts/dkr.sh))
    (pkgs.writeScriptBin "fv" (builtins.readFile ./scripts/fv.sh))
    (pkgs.writeScriptBin "fzf-git" (builtins.readFile ./scripts/fzf-git.sh))
    (pkgs.writeScriptBin "fzmv" (builtins.readFile ./scripts/fzmv.sh))
    (pkgs.writeScriptBin "fztop" (builtins.readFile ./scripts/fztop.sh))
    (pkgs.writeScriptBin "gitup" (builtins.readFile ./scripts/gitup.sh))
    (pkgs.writeScriptBin "igr" (builtins.readFile ./scripts/igr.sh))
    (pkgs.writeScriptBin "rgf" (builtins.readFile ./scripts/rgf.sh))
    (pkgs.writeScriptBin "sshget" (builtins.readFile ./scripts/sshget.sh))
    (pkgs.writeScriptBin "sysz" (builtins.readFile ./scripts/sysz.sh))
    (pkgs.writeScriptBin "wifiz" (builtins.readFile ./scripts/wifiz.sh))
  ];

  # Copy these scripts to the user's home directory for dotfiles repo
  home.file.".config/scripts" = {
    source = ./scripts;
    recursive = true;
  };

  # Set FZF environment variables
  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv --exclude target --exclude dist --exclude build";
    FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv --exclude target --exclude dist --exclude build";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv --exclude target --exclude dist --exclude build";
    # Additional preview options for keybindings
    FZF_CTRL_T_OPTS = "--preview 'bat --style=numbers --color=always --line-range=:500 {}'";
    FZF_ALT_C_OPTS = "--preview 'eza --tree --level=2 --color=always {}'";
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
    changeDirWidgetCommand = "fd --type d --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv --exclude target --exclude dist --exclude build";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --level=2 --color=always {} | head -100'"
      "--bind=ctrl-o:execute(xdg-open {} &)"
      "--bind=ctrl-e:execute($EDITOR {} || nvim {})"
      "--header='CTRL-O: open | CTRL-E: edit'"
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
    defaultCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv --exclude target --exclude dist --exclude build";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border=rounded"
      "--info=inline"
      "--bind=ctrl-j:down,ctrl-k:up,ctrl-h:toggle-preview"
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-u:preview-half-page-up"
      "--bind=ctrl-d:preview-half-page-down"
      "--bind=ctrl-f:preview-page-down"
      "--bind=ctrl-b:preview-page-up"
      "--bind=ctrl-g:preview-top"
      "--bind=ctrl-shift-g:preview-bottom"
      "--bind=alt-a:select-all"
      "--bind=alt-d:deselect-all"
      "--preview='([[ -d {} ]] && eza --tree --level=2 --color=always {} | head -200) || (file {} | grep -q binary && echo {} is binary) || bat --style=numbers --color=always --line-range=:500 {}'"
      "--preview-window=right:50%:wrap"
      "--multi"
      "--cycle"
      "--reverse"
      "--marker=▶"
      "--pointer=◀"
      "--prompt=❯ "
    ];
    fileWidgetCommand = "fd --type f --follow --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv --exclude target --exclude dist --exclude build";
    fileWidgetOptions = [
      "--preview '([[ -d {} ]] && eza --tree --level=2 --color=always {} | head -100) || (file {} | grep -q binary && echo {} is binary) || bat --style=numbers --color=always --line-range=:500 {}'"
      "--bind=ctrl-o:execute(xdg-open {} &)"
      "--bind=ctrl-e:execute($EDITOR {} || nvim {})"
      "--bind=ctrl-y:execute-silent(echo -n {} | wl-copy)"
      "--header='CTRL-O: open | CTRL-E: edit | CTRL-Y: copy path'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
      "--tac"
      "--tiebreak=index"
      "--preview 'echo {}'"
      "--preview-window=up:3:hidden:wrap"
      "--bind=ctrl-h:toggle-preview"
      "--bind=ctrl-y:execute-silent(echo -n {} | wl-copy)"
      "--header='Press CTRL-Y to copy command into clipboard'"
    ];
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

}
