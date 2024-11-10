{
  lib,
  ...
}:

{
  imports = [
    ./global

    ./features/atuin
    ./features/bat
    ./features/cli
    ./features/compression
    ./features/eza
    ./features/fastfetch
    ./features/fd
    ./features/fzf
    ./features/git
    ./features/kubernetes
    ./features/lazygit
    ./features/networking-utils
    ./features/nixvim
    ./features/ripgrep
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/tmux
    ./features/yazi
    ./features/zoxide
  ];

  programs.bash.bashrcExtra = ''
    [[ -f /opt/vultr/vultr_app.sh ]] && . /opt/vultr/vultr_app.sh
  '';

  # Whether to enable settings that make Home Manager work better on GNU/Linux distributions other than NixOS.
  targets.genericLinux.enable = true;

  home.username = lib.mkForce "root";
  home.homeDirectory = lib.mkForce "/root";
}