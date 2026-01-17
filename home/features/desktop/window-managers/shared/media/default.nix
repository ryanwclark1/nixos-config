{
  pkgs,
  ...
}:

{
  imports = [
    ./screenrecord.nix  # Screen recording with area selection
    ./screenshot-enhanced.nix  # Enhanced screenshot workflow
    ./swayosd
    ./waypaper
  ];

  home.packages = with pkgs; [
    wiremix
  ];
}
