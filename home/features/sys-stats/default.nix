{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # system tools
    sysstat
    lm_sensors # for `sensors` command
    inxi
    dmidecode
    glxinfo
    xorg.xdpyinfo
  ];
}