{
  config,
  lib,
  ...
}:

{
  imports = [
    ./features/shell
    ./features/atuin
    ./features/bat
    ./features/cli
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/fzf
    ./features/git
    ./features/kitty
    ./features/lazygit
    ./features/ripgrep
    ./features/starship
    ./features/tmux
    ./features/yazi
    ./features/zoxide
  ];

  targets.darwin.search = "Google";

  # git also optional with full configuration
  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home.username = lib.mkDefault "administrator";
  home.stateVersion = lib.mkDefault "24.11";
  home.homeDirectory = lib.mkForce "/Users/${config.home.username}";
  # home.username = lib.mkForce "administrator";
  # Disable impermanence
  # home.persistence = lib.mkForce {};
}
