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

  # Import fzf scripts module
  fzfScripts = import ../desktop/common/scripts/fzf/default.nix {
    inherit pkgs lib;
  };

in
fzfScripts
// {
  # FZF module automatically sets FZF_DEFAULT_COMMAND, FZF_CTRL_T_COMMAND, and FZF_ALT_C_COMMAND
  # based on defaultCommand, fileWidgetCommand, and changeDirWidgetCommand respectively.
  # We only need to set additional options that aren't covered by the module.

  programs.fzf = {
    enable = true;
    package = pkgs.fzf;
    tmux = {
      enableShellIntegration = lib.mkIf config.programs.tmux.enable true;
      shellIntegrationOptions = [
        "center,80%,40%"
      ];
    };

    colors = {
      fg = "#${base05}";
      bg = "-1"; # use terminal background
      hl = "#${base0E}";
      "fg+" = "#${base05}";
      "bg+" = "#${base02}"; # selected line background
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
    # Default --exclude options moved to fd configuration
    # Can explicitly state excludes in fd commands if desired

    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border=rounded"
      "--info=inline"
      "--ansi"
      "--tabstop=2"
      "--preview-window=right,60%,border-rounded"
      "--preview 'fzf-preview {}'"
      "--multi"
      "--cycle"
      "--marker=▶"
      "--pointer=◀"
      "--prompt=❯ "

      # --- Keybinds ---
      # Toggle preview with ctrl+/
      # "--bind=ctrl-/:toggle-preview"
      # "--bind=alt-p:change-preview-window(right,60%,border-rounded|down,40%,border-rounded)"
      # Navigation
      # "--bind=ctrl-j:down"
      # "--bind=ctrl-k:up"
      # "--bind=ctrl-f:page-down"
      # "--bind=ctrl-b:page-up"
      # "--bind=ctrl-l:clear-query"
      # Sorting (ctrl-s toggles between relevance and alphabetical)
      # "--bind=ctrl-s:toggle-sort"
      # Select all with ctrl-a (more standard than alt-a)
      # "--bind=ctrl-a:select-all"
      # "--bind=ctrl-d:deselect-all"
      # Open in editor - using become to replace fzf process with nvim
      # "--bind=ctrl-o:become(nvim \\{+\\})"  # Temporarily disabled due to placeholder issues
      # Copy to clipboard
      # "--bind=ctrl-y:execute-silent(echo \\{+\\} | wl-copy)"  # Temporarily disabled due to placeholder issues
    ];

    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = [
      # "--preview=${previewScript}"

      # --- Keybinds ---
      # Toggle preview with ctrl+/
      "--bind=ctrl-/:toggle-preview"
      "--bind=alt-p:change-preview-window(right,60%,border-rounded|down,40%,border-rounded)"
      # Navigation
      "--bind=ctrl-j:down"
      "--bind=ctrl-k:up"
      "--bind=ctrl-f:page-down"
      "--bind=ctrl-b:page-up"
      "--bind=ctrl-l:clear-query"
      # Sorting (ctrl-s toggles between relevance and alphabetical)
      "--bind=ctrl-s:toggle-sort"
      # Select all with ctrl-a (more standard than alt-a)
      "--bind=ctrl-a:select-all"
      "--bind=ctrl-d:deselect-all"
      # Open in editor - using become to replace fzf process with nvim
      # "--bind=ctrl-o:become(nvim \\{+\\})"  # Temporarily disabled due to placeholder issues
      # Copy to clipboard
      # "--bind=ctrl-y:execute-silent(echo \\{+\\} | wl-copy)"  # Temporarily disabled due to placeholder issues
      # Reuse global binds; add one to open parent directory of selection
      # "--bind=alt-o:execute(cd $(dirname -- \\{q\\}) && $SHELL)"  # Temporarily disabled due to placeholder issues
    ];

    changeDirWidgetCommand = "fd --type d";
    changeDirWidgetOptions = [
      "--preview 'fzf-preview {}'"

      # Navigation bindings consistent with other widgets
      "--bind=ctrl-j:down"
      "--bind=ctrl-k:up"
      "--bind=ctrl-f:page-down"
      "--bind=ctrl-b:page-up"
      "--bind=ctrl-l:clear-query"

      # Preview control
      "--bind=ctrl-/:toggle-preview"
      "--bind=alt-p:change-preview-window(right,60%,border-rounded|down,40%,border-rounded)"

      # Directory-specific: enter accepts the directory
      "--bind=enter:accept"
    ];

    # historyWidgetOptions = [
    #   # Keep shell order (recency)
    #   "--no-sort"
    #   "--tiebreak=index"

    #   # Simple preview showing the command
    #   "--preview=echo {}"
    #   "--preview-window=up:3:wrap"

    #   # Basic navigation
    #   "--bind=ctrl-k:up"
    #   "--bind=ctrl-j:down"
    #   "--bind=ctrl-/:toggle-preview"

    #   # Copy command to clipboard
    #   # "--bind=ctrl-y:execute-silent(echo -n \\{\\} | wl-copy)"  # Temporarily disabled due to placeholder issues
    # ];

    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };
}
