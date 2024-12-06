{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.monaspace
    nerd-fonts.mplus
    nerd-fonts.noto
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu-sans
    nerd-fonts.symbols-only
    nerd-fonts.hack
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
    powerline-symbols
    font-awesome

    # Font Manager
    font-manager
  ];

  fonts.fontconfig.enable = true;
}