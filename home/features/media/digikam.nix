# Photo Management Program from KDE
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    digikam
  ];
}
