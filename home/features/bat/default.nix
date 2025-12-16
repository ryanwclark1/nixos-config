# bat - A cat clone with syntax highlighting and Git integration
# See: https://github.com/sharkdp/bat
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./theme.tmTheme.nix
  ];

  programs.bat = {
    enable = true;
    package = pkgs.bat;

    # Additional bat-related packages for enhanced functionality
    extraPackages = with pkgs.bat-extras; [
      batdiff # Diff tool with syntax highlighting
      # batgrep     # Temporarily disabled due to test suite failures in nixpkgs-unstable
      batman # Manual page viewer with syntax highlighting
      batpipe # Pipe integration for less/more
      batwatch # File watcher with syntax highlighting
      prettybat # Prettier for bat output
    ];

    # Bat configuration options
    # See: https://github.com/sharkdp/bat#configuration-file
    # The config attribute accepts bat's TOML config file options
    config = {
      # Use less as pager with flags:
      # -F: quit if one screen
      # -R: allow ANSI color escapes
      pager = "less -FR";

      # Use our custom theme (defined in theme.tmTheme.nix)
      theme = "theme";

      # Map file extensions to syntaxes (example)
      # map-syntax = [
      #   "*.jenkinsfile:Groovy"
      #   "*.props:Java Properties"
      # ];
    };

    # Additional syntax definitions (if needed)
    # syntaxes = with pkgs.bat-extras; [
    #   # Add custom syntaxes here if needed
    # ];

    # Additional themes (if needed)
    # themes = with pkgs.bat-extras; [
    #   # Add additional themes here if needed
    # ];
  };

  # Shell aliases for bat
  home.shellAliases = {
    # Replace cat with bat, using plain mode to maintain cat-like behavior
    # --plain: disable decorations (headers, line numbers)
    # --color=always: always use colors (even when piping)
    cat = "bat --plain --color=always";
    # Note: batpipe is automatically used by less through LESSOPEN
    # configured in shell/common.nix
  };
}
