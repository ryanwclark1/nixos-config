{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs;[
    libv4l
    libcamera
  ];
}