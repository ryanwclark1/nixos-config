{
  pkgs,
  ...
}:

{
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrains Mono" "FiraCode Nerd Font" "Ubuntu Nerd Font"];
        sansSerif = [ "NotoSans Nerd Font" "DejaVu Sans" "UbuntuSans Nerd Font"];
        serif = [ "NotoSerif Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

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
    
    font-awesome_5
    icomoon-feather
    jetbrains-mono
    liberation_ttf
    material-symbols
    noto-fonts
    noto-fonts-extra
    noto-fonts-emoji
    powerline-fonts
    powerline-symbols
    # Font Manager
    font-manager
  ];

}