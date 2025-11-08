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
      useEmbeddedBitmaps = true;
      includeUserConf = true;
      defaultFonts = {
        monospace = [ "DejaVu Sans Mono" ];
        sansSerif = [ "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    packages = with pkgs; [
    nerd-fonts._0xproto
    nerd-fonts.arimo
    nerd-fonts.bigblue-terminal
    nerd-fonts.bitstream-vera-sans-mono
    nerd-fonts.code-new-roman
    nerd-fonts.comic-shanns-mono
    nerd-fonts.commit-mono
    nerd-fonts.cousine
    nerd-fonts.d2coding
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.departure-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.go-mono
    nerd-fonts.hack
    nerd-fonts.heavy-data
    nerd-fonts.im-writing
    nerd-fonts.jetbrains-mono
    nerd-fonts.liberation
    nerd-fonts.lilex
    nerd-fonts.monaspace
    nerd-fonts.monofur
    nerd-fonts.noto
    nerd-fonts.open-dyslexic
    nerd-fonts.overpass
    nerd-fonts.profont
    nerd-fonts.roboto-mono
    nerd-fonts.sauce-code-pro
    nerd-fonts.shure-tech-mono
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
    nerd-fonts.terminess-ttf
    nerd-fonts.tinos
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu-sans
    nerd-fonts.victor-mono
    nerd-fonts.zed-mono

    # dejavu-fonts
    # fira-code-symbols
    # font-awesome_5
    icomoon-feather
    # liberation_ttf
    # material-symbols
    # noto-fonts
    noto-fonts-color-emoji
    # noto-fonts-extra
    powerline-fonts
    powerline-symbols
    ];
  };
}
