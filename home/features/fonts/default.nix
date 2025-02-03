{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.arimo
    nerd-fonts.bigblue-terminal
    nerd-fonts.code-new-roman
    nerd-fonts.comic-shanns-mono
    nerd-fonts.commit-mono
    nerd-fonts.cousine
    nerd-fonts.d2coding
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.departure-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.envy-code-r
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.mplus
    nerd-fonts.noto
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu-sans
    nerd-fonts.symbols-only
    jetbrains-mono
    liberation_ttf
    powerline-fonts
    powerline-symbols
    icomoon-feather
    font-awesome
    material-symbols
    # Font Manager
    font-manager
  ];

  fonts.fontconfig.enable = true;
}