# Enhanced shell configuration with additional Home Manager options
{ config, lib, pkgs, ... }:

{


  # Carapace - Multi-shell completion framework
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  # Dircolors configuration
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    # Use vivid for LS_COLORS instead of settings here
    # settings = { ... };
  };

  # Environment variables for better defaults
  home.sessionVariables = {
    # History control
    HISTCONTROL = lib.mkDefault "ignoreboth:erasedups";
    HISTTIMEFORMAT = lib.mkDefault "%F %T ";

    # Locale settings (if not set system-wide)
    # LANG = lib.mkDefault "en_US.UTF-8";
    # LC_ALL = lib.mkDefault "en_US.UTF-8";

    # Terminal
    COLORTERM = lib.mkDefault "truecolor";

    # # GPG TTY for signing
    # GPG_TTY = lib.mkDefault "$(tty)";

    # # Python
    # PYTHONDONTWRITEBYTECODE = lib.mkDefault "1";

    # # Rust
    # RUST_BACKTRACE = lib.mkDefault "1";

    # # Go
    # GOPATH = lib.mkDefault "$HOME/go";

    # # Node.js
    # NPM_CONFIG_PREFIX = lib.mkDefault "$HOME/.npm-global";

    # # Docker
    # DOCKER_BUILDKIT = lib.mkDefault "1";
    # COMPOSE_DOCKER_CLI_BUILD = lib.mkDefault "1";
  };

  # Note: Global gitignore is configured in ../git/default.nix via programs.git.ignores
}
