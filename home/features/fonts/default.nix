{
  pkgs,
  ...
}:

{
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "DejaVu Sans Mono" ];
        sansSerif = [ "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.bigblue-terminal
    nerd-fonts.d2coding
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.departure-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.envy-code-r
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.mplus
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu-sans
    nerd-fonts.symbols-only

    dejavu-fonts
    fira-code-symbols
    font-awesome_5
    icomoon-feather
    jetbrains-mono
    liberation_ttf
    material-symbols
    noto-fonts
    noto-fonts-emoji
    noto-fonts-extra
    powerline-fonts
    powerline-symbols
    
    # Font Manager
    font-manager
  ];

}