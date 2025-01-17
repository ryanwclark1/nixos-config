# ./host/common/fonts.nix
{
  pkgs,
  ...
}:

{
  fonts = {
    fontconfig = {
      enable = true;
      allowBitmaps = true;
      antialias = true;
    };
    packages = with pkgs; [
      nerd-fonts._0xproto
      nerd-fonts._3270
      nerd-fonts.agave
      nerd-fonts.anonymice
      nerd-fonts.arimo
      nerd-fonts.aurulent-sans-mono
      nerd-fonts.bigblue-terminal
      nerd-fonts.bitstream-vera-sans-mono
      nerd-fonts.blex-mono
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.code-new-roman
      nerd-fonts.comic-shanns-mono
      nerd-fonts.commit-mono
      nerd-fonts.cousine
      nerd-fonts.d2coding
      nerd-fonts.daddy-time-mono
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.departure-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.envy-code-r
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.monaspace
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
      font-awesome
      material-symbols
    ];
  };
}