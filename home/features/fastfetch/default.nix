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
            width = 22;
            height = 11;
          };
        };
        modules = [
          "break"
          {
              type = "custom";
              format = "\u001b[90m┌──────────────────────Hardware──────────────────────┐";
          }
          {
              type = "host";
              key = " PC";
              keyColor = "green";
          }
          {
              type = "cpu";
              key = "│ ├";
              "showPeCoreCount" = true;
              keyColor = "green";
          }
          {
              type = "gpu";
              key = "│ ├󰍛";
              keyColor = "green";
          }
          {
              type = "memory";
              key = "│ ├󰍛";
              keyColor = "green";
          }
          {
              type = "disk";
              key = "└ └";
              keyColor = "green";
          }
          {
              type = "custom";
              format = "\u001b[90m└────────────────────────────────────────────────────┘";
          }
          "break"
          {
              type = "custom";
              format = "\u001b[90m┌──────────────────────Software──────────────────────┐";
          }
          {
              type = "os";
              key = " OS";
              keyColor = "yellow";
          }
          {
              type = "kernel";
              key = "│ ├";
              keyColor = "yellow";
          }
          {
              type = "packages";
              key = "│ ├󰏖";
              keyColor = "yellow";
          }
          {
              type = "shell";
              key = "└ └";
              keyColor = "yellow";
          }
          "break"
          {
              type = "de";
              key = " DE";
              keyColor = "blue";
          }
          {
              type = "lm";
              key = "│ ├";
              keyColor = "blue";
          }
          {
              type = "wm";
              key = "│ ├";
              keyColor = "blue";
          }
          {
              type = "wmtheme";
              key = "│ ├󰉼";
              keyColor = "blue";
          }
          {
              type = "gpu";
              key = "└ └󰍛";
              format = "{3}";
              keyColor = "blue";
          }
          {
              type = "custom";
              format = "\u001b[90m└────────────────────────────────────────────────────┘";
          }
          "break"
          {
              type = "custom";
              format = "\u001b[90m┌────────────────────Uptime / Age────────────────────┐";
          }
          {
              type = "command";
              key = "  OS Age ";
              keyColor = "magenta";
              text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
          }
          {
              type = "uptime";
              key = "  Uptime ";
              keyColor = "magenta";
          }
          {
              type = "custom";
              format = "\u001b[90m└────────────────────────────────────────────────────┘";
          }
          "break"
        ];
        # modules= [
        #   "title"
        #   "separator"
        #   "os"
        #   "host"
        #   "bios"
        #   "bootmgr"
        #   "board"
        #   "chassis"
        #   "kernel"
        #   "initsystem"
        #   "uptime"
        #   "processes"
        #   "packages"
        #   "shell"
        #   "editor"
        #   "display"
        #   "brightness"
        #   "monitor"
        #   "terminal"
        #   {
        #     type = "cpu";
        #     showPeCoreCount = true;
        #     temp = true;
        #   }
        #   "cpuusage"
        #   {
        #     type = "gpu";
        #     driverSpecific = true;
        #     temp = true;
        #   }
        #   "memory"
        #   "physicalmemory"
        #   "swap"
        #   "disk"
        #   "battery"
        #   "poweradapter"
        #   "player"
        #   "media"
        #   {
        #     type = "publicip";
        #     timeout = 1000;
        #   }
        #   {
        #     type = "localip";
        #     showIpv6 = true;
        #     showMac = true;
        #   }
        #   "dns"
        #   "wifi"
        #   "datetime"
        #   "locale"
        #   "vulkan"
        #   "opengl"
        #   "opencl"
        #   "users"
        #   "bluetooth"
        #   "bluetoothradio"
        #   "sound"
        #   "diskio"
        #   {
        #     type = "physicaldisk";
        #     temp = true;
        #   }
        #   "break"
        #   "colors"
        # ];
      };
    };
  };

  home.shellAliases = {
    neofetch = "fastfetch";
    fetch = "fastfetch";
  };

}