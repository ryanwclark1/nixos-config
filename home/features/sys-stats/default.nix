{
  pkgs,
  ...
}:

# inxi -Fxxxmprz <--- all info with filters
{
  home.packages = with pkgs; [
    sysstat
    lm_sensors # for `sensors` command
    inxi
    dmidecode
    glxinfo
    xorg.xdpyinfo
  ];
}
