# ./host/common/fonts.nix
{
  pkgs,
  ...
}:

{
  fonts = {
    fontconfig = {
      enable = true;
      subpixel.rgba = "rgb";
      allowBitmaps = true;
      antialias = true;
    };
    packages = with pkgs; [
      nerdfonts
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      # powerline-fonts
      powerline-symbols
    ];
  };
}