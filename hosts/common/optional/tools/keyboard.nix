{
  pkgs,
  ...
}:

{
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = with pkgs; [
    via
    libxkbcommon
  ];

  services.udev.packages = [
    pkgs.via
  ];
}
