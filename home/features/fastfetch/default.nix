{
  config,
  pkgs,
  ...
}:

{
    home.file.".config/fastfetch/assets" = {
      source = ./assets;
      recursive = true;
    };


  programs = {
    fastfetch = {
      enable = true;
      package = pkgs.fastfetch;
      settings = {
        logo = {
          # source = "${config.home.homeDirectory}/.config/fastfetch/assets/nixos.png";
          type = "auto";
          position = "left";
          padding = {
            top = 1;
            right = 2;
            left = 0;
          };
          # width = 40; # 22
          # height = 25; # 11
        };
        display = {
          color = {
            keys = "35";
            output = "90";
          };
        };
        modules = [
          "break"
          {
            type = "custom";
            format = "┌───────────────────────Hardware───────────────────────┐";
          }
          # {
            # type = "command";
          #   shell = "/bin/sh";
          #   test = "echo $HOSTNAME";
          #   key = " PC";
          #   keyColor = "green";

          # }
          {
            type = "title";
            key = "  PC";
            keyColor = "green";
            format = "{host-name}";
          }
          {
            type = "cpu";
            key = "│ ├ ";
            "showPeCoreCount" = true;
            keyColor = "green";
          }
          {
            type = "gpu";
            key = "│ ├󰢮 ";
            keyColor = "green";
          }
          {
            type = "memory";
            key = "│ ├󰑭 ";
            keyColor = "green";
          }
          {
            type = "disk";
            key = "│ ├󰋊 ";
            keyColor = "green";
          }
          {
            type = "display";
            key = "└ └󰍹 ";
            keyColor = "green";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────┘";
          }
          "break"
          {
            type = "custom";
            format = "┌───────────────────────Software───────────────────────┐";
          }
          {
            type = "os";
            key = " OS";
            keyColor = "yellow";
          }
          {
            type = "kernel";
            key = "│ ├ ";
            keyColor = "yellow";
          }
          {
            type = "packages";
            key = "│ ├󰏖 ";
            keyColor = "yellow";
          }
          {
            type = "shell";
            key = "│ ├ ";
            keyColor = "yellow";
          }
          {
            type = "terminal";
            key = "└ └ ";
            keyColor = "yellow";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────┘";
          }
          # "break"
          # {
          #   type = "custom";
          #   format = "┌────────────────────Uptime/Age────────────────────┐";
          # }
          # {
          #   type = "command";
          #   key = " 󱦟 OS Age ";
          #   keyColor = "magenta";
          #   text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
          # }
          # {
          #   type = "uptime";
          #   key = " 󱫐 Uptime ";
          #   keyColor = "magenta";
          # }
          # {
          #   type = "custom";
          #   format = "└──────────────────────────────────────────────────┘";
          # }
          "break"
          {
            type = "custom";
            format = "┌───────────────────────Network───────────────────────┐";
          }
          {
            type = "localip";
            key = "󰩟 IP";
            showIpv6 = false;
            showMac = false;
            keyColor = "red";
            format = "{ifname}";
          }
          {
            type = "localip";
            key = "│ ├ ";
            showIpv6 = false;
            showMac = false;
            keyColor = "red";
            format = "{ipv4} {ifname}";
          }
          {
            type = "publicip";
            timeout = 1000;
            key = "└ └ ";
            keyColor = "red";
          }
          {
            type = "custom";
            format = "└────────────────────────────────────────────────────┘";
          }
        ];
      };
    };
  };

  home.shellAliases = {
    neofetch = "fastfetch";
    fetch = "fastfetch";
  };

}