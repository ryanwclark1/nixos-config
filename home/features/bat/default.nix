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
    };
  };
}
