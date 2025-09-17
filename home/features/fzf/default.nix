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

  previewCmd = ''
    p="{}"
    if [ -d "$p" ]; then
      if command -v eza >/dev/null 2>&1; then
        eza --tree --level=2 --color=always "$p" | head -200
      else
        ls -la --color=always "$p" 2>/dev/null || tree -L 2 "$p" 2>/dev/null
      fi
    elif [ -f "$p" ]; then
      mime="$(file --mime-type -Lb "$p" 2>/dev/null || echo)"
      case "$mime" in
        text/*|application/json|application/xml|application/x-sh|application/x-yaml|application/yaml)
          if command -v bat >/dev/null 2>&1; then
            bat --style=numbers --color=always --line-range :500 "$p"
          else
            sed -n "1,500p" "$p"
          fi
          ;;
        *)
          # Binary/unknown: show type + a safe hex/ascii preview
          file -b "$p" 2>/dev/null || true
          if command -v hexdump >/dev/null 2>&1; then
            hexdump -C -n 1024 "$p"
          elif command -v xxd >/dev/null 2>&1; then
            xxd -g 1 -l 1024 "$p"
          else
            head -c 1024 "$p" | od -An -tx1 -v
          fi
          ;;
      esac
    else
      file --brief --mime "$p" 2>/dev/null || true
    fi
  '';

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

  # FZF module automatically sets FZF_DEFAULT_COMMAND, FZF_CTRL_T_COMMAND, and FZF_ALT_C_COMMAND
  # based on defaultCommand, fileWidgetCommand, and changeDirWidgetCommand respectively.
  # We only need to set additional options that aren't covered by the module.

  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
    tmux = {
      enableShellIntegration = lib.mkIf config.programs.tmux.enable true;
      shellIntegrationOptions = [
        "-p 80%,80%"
      ];
    };

    colors = {
      fg = "#${base05}";
      bg = "-1";              # use terminal background
      hl = "#${base0E}";
      "fg+" = "#${base05}";
      "bg+" = "#${base02}";      # selected line background
      "hl+" = "#${base0D}";
      info = "#${base0C}";
      border = "#${base03}";
      prompt = "#${base0A}";
      pointer = "#${base08}";
      marker = "#${base0B}";
      spinner = "#${base0C}";
      header = "#${base07}";
      gutter = "#${base01}";
      label = "#${base06}";
      query = "#${base06}";
    };
    # Default --exclude opetions moved to fd configuration can explicitly state if desiredfuzzyCompletion
    # Consider adding back --strip-cwd-prefix

    defaultCommand = "fd --hidden --follow";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border=rounded"


      "--ansi"
      "--tabstop=2"
      "--preview-window=right,60%,border-rounded"
      "--preview=${previewCmd}"
      # "--preview-window=right:50%:wrap"
      # "--multi"
      # "--cycle"
      # "--reverse"
      # "--info=inline"
      "--marker=▶"
      "--pointer=◀"
      "--prompt=❯ "

      # --- Keybinds ---
      # Toggle/show preview & move it around
      "--bind=?:toggle-preview"
      "--bind=alt-p:change-preview-window(right,60%,border-rounded|down,40%,border-rounded)"
      # Scroll preview
      "--bind=ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down"
      "--bind=alt-u:preview-up,alt-d:preview-down"
      # Navigation
      "--bind=ctrl-j:down"
      "--bind=ctrl-k:up"
      "--bind=ctrl-f:page-down"
      "--bind=ctrl-b:page-up"
      "--bind=ctrl-l:clear-query"
      "--bind=ctrl-s:toggle-sort"
      "--bind=alt-a:toggle-all"
      # Open selection(s) in editor
      "--bind=ctrl-o:execute(nvim {+} < /dev/tty > /dev/tty 2>&1)"
      # Copy selected paths to clipboard
      "--bind=ctrl-y:execute-silent(echo -n {+} | wl-copy)"
      # Show file type quickly (helps on binaries)
      "--bind=ctrl-i:execute-silent(file --brief --mime {+} 2>/dev/null || true)"
    ];

    fileWidgetCommand = "fd --type f --hidden --follow";
    fileWidgetOptions = [
      "--preview=${previewCmd}"

      # --- Keybinds ---
      # Toggle/show preview & move it around
      "--bind=?:toggle-preview"
      "--bind=alt-p:change-preview-window(right,60%,border-rounded|down,40%,border-rounded)"
      # Scroll preview
      "--bind=ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down"
      "--bind=alt-u:preview-up,alt-d:preview-down"
      # Navigation
      "--bind=ctrl-j:down"
      "--bind=ctrl-k:up"
      "--bind=ctrl-f:page-down"
      "--bind=ctrl-b:page-up"
      "--bind=ctrl-l:clear-query"
      "--bind=ctrl-s:toggle-sort"
      "--bind=alt-a:toggle-all"
      # Open selection(s) in editor
      "--bind=ctrl-o:execute(nvim {+} < /dev/tty > /dev/tty 2>&1)"
      # Copy selected paths to clipboard
      "--bind=ctrl-y:execute-silent(echo -n {+} | wl-copy)"
      # Show file type quickly (helps on binaries)
      "--bind=ctrl-i:execute-silent(file --brief --mime {+} 2>/dev/null || true)"
      # Reuse global binds; add one to open parent directory of selection
      "--bind=alt-o:execute(cd $(dirname -- {q}) && $SHELL)"
    ];

    changeDirWidgetCommand = "fd --type d --hidden --follow";
    changeDirWidgetOptions = [
      "--preview=${previewCmd}"

      # Enter directory (default behavior)
      "--bind=enter:accept"
    ];

    historyWidgetOptions = [
      # Keep shell order (recency)
      "--no-sort"
      "--tiebreak=index"
      
      # Simple preview showing the command
      "--preview=echo {}"
      "--preview-window=up:3:wrap"
      
      # Basic navigation
      "--bind=ctrl-k:up"
      "--bind=ctrl-j:down"
      "--bind=?:toggle-preview"
      
      # Copy command to clipboard
      "--bind=ctrl-y:execute-silent(echo -n {} | wl-copy)"
    ];
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

}


      # "--bind=ctrl-j:down,ctrl-k:up,ctrl-h:toggle-preview"
      # "--bind=ctrl-/:toggle-preview"
      # "--bind=ctrl-u:preview-half-page-up"
      # "--bind=ctrl-d:preview-half-page-down"
      # "--bind=ctrl-f:preview-page-down"
      # "--bind=ctrl-b:preview-page-up"
      # "--bind=ctrl-g:preview-top"
      # "--bind=ctrl-shift-g:preview-bottom"
      # "--bind=alt-a:select-all"
      # "--bind=alt-d:deselect-all"


      # "--bind=ctrl-o:execute(xdg-open {} &)"
      # "--bind=ctrl-e:execute($EDITOR {} || nvim {})"
      # "--bind=ctrl-y:execute-silent(echo -n {} | wl-copy)"
      # "--header='CTRL-O: open | CTRL-E: edit | CTRL-Y: copy path'"

      # "--preview 'eza --tree --level=2 --color=always {} | head -100'"
      # "--bind=ctrl-o:execute(xdg-open {} &)"
      # "--bind=ctrl-e:execute($EDITOR {} || nvim {})"
      # "--header='CTRL-O: open | CTRL-E: edit'"
