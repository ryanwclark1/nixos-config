{
  config,
  lib,
  ...
}:

{
  imports = [
    ./features/shell
    ./features/atuin
    ./features/ai/gemini
    ./features/bat
    ./features/cli
    ./features/development
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/fzf
    ./features/git
    ./features/lazygit
    ./features/ripgrep
    ./features/starship
    ./features/tmux
    ./features/yazi
    ./features/zoxide
  ];

  targets.darwin.search = "Google";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home.username = lib.mkDefault "ryanclark";
  home.stateVersion = lib.mkDefault "24.11";
  home.homeDirectory = lib.mkForce "/Users/${config.home.username}";
}
