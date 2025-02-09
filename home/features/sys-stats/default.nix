{
  pkgs,
  ...
}:

# inxi -Fxxxmprz <--- all info with filters
{
  home.packages = with pkgs; [
    inxi # Full featured CLI system information tool.
    glxinfo # Collection of demos and test programs for OpenGL and Mesa.
    libgtop # Library that reads information about processes and the running system.
  ] ++ (if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then [
    sysstat # Collection of performance monitoring tools for Linux (such as sar, iostat and pidstat)
    dmidecode # Tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard.
  ] else []);
}

