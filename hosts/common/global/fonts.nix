# ./host/common/fonts.nix
{ pkgs
, ...
}:

{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    hack-font
    proggyfonts
    powerline-fonts
    powerline-symbols
    jetbrains-mono
    fira-code
    font-awesome
    nerdfonts
  ];
}
