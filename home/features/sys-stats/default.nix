{
  pkgs,
  ...
}:

# inxi -Fxxxmprz <--- all info with filters
{
  home.packages = with pkgs; [
    sysstat
    inxi
    dmidecode
    glxinfo
  ];
}
