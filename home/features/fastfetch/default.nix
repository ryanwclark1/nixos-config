{
  pkgs,
  ...
}:

{

  programs = {
    fastfetch = {
      enable = true;
      package = pkgs.fastfetch;
      settings = {
        logo = {
          padding = {
            top = 2;
          };
        };
        modules= [
          "title"
          "separator"
          "os"
          "host"
          "bios"
          "bootmgr"
          "board"
          "chassis"
          "kernel"
          "initsystem"
          "uptime"
          "processes"
          "packages"
          "shell"
          "editor"
          "display"
          "brightness"
          "monitor"
          "lm"
          "de"
          "wm"
          "wmtheme"
          "theme"
          "icons"
          "font"
          "cursor"
          "terminal"
          "terminalfont"
          "terminalsize"
          "terminaltheme"
          {
            type = "cpu";
            showPeCoreCount = true;
            temp = true;
          }
          "cpucache"
          "cpuusage"
          {
            type = "gpu";
            driverSpecific = true;
            temp = true;
          }
          "memory"
          "physicalmemory"
          "swap"
          "disk"
          "battery"
          "poweradapter"
          "player"
          "media"
          {
            type = "publicip";
            timeout = 1000;
          }
          {
            type = "localip";
            showIpv6 = true;
            showMac = true;
          }
          "dns"
          "wifi"
          "datetime"
          "locale"
          "vulkan"
          "opengl"
          "opencl"
          "users"
          "bluetooth"
          "bluetoothradio"
          "sound"
          "camera"
          "gamepad"
          "netio"
          "diskio"
          {
            type = "physicaldisk";
            temp = true;
          }
          "break"
          "colors"
        ];
      };
    };
  };

  home.shellAliases = {
    neofetch = "fastfetch";
    fetch = "fastfetch";
  };

}