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
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      powerline-symbols
    ];
  };
}