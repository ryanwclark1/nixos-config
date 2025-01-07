{
  pkgs,
  ...
}:

{
  home.file.".config/fastfetch/assets" = {
    source = ./assets;
    recursive = true;
  };


  programs =
  let
    # base00 = "38;2;48;52;70";
    # base01 = "38;2;41;44;60";
    # base02 = "38;2;65;69;89";
    # base03 = "38;2;81;87;109";
    # base04 = "38;2;98;104;128";
    # base05 = "38;2;198;208;245";
    # base06 = "38;2;242;213;207";
    # base07 = "38;2;186;187;241";
    # base08 = "38;2;231;130;132";
    # base09 = "38;2;239;159;118";
    # base0A = "38;2;229;200;144";
    # base0B = "38;2;166;209;137";
    # base0C = "38;2;129;200;190";
    # base0D = "38;2;140;170;238";
    base0E = "38;2;202;158;230";
    # base0F = "38;2;238;190;190";
  in
  {
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
          # color = {
          #   keys = "35";
          #   output = "90";
          # };
        };
        modules = [
          "break"
          {
            type = "custom";
            format = "┌─────────────────────Hardware──────────────────────┐";
          }
          {
            type = "title";
            key = "  PC";
            keyColor = "${base0E}";
            format = "{host-name}";
          }
          {
            type = "cpu";
            key = "│ ├ ";
            "showPeCoreCount" = true;
            keyColor = "${base0E}";
          }
          {
            type = "gpu";
            key = "│ ├󰢮 ";
            keyColor = "${base0E}";
          }
          {
            type = "memory";
            key = "│ ├󰑭 ";
            keyColor = "${base0E}";
          }
          {
            type = "disk";
            key = "│ ├󰋊 ";
            keyColor = "${base0E}";
          }
          {
            type = "display";
            key = "└ └󰍹 ";
            keyColor = "${base0E}";
          }
          {
            type = "custom";
            format = "└───────────────────────────────────────────────────┘";
          }
          # "break"
          {
            type = "custom";
            format = "┌─────────────────────Software──────────────────────┐";
          }
          {
            type = "os";
            key = " OS";
            keyColor = "${base0D}";
            format = "{3} {10}";
          }
          {
            type = "kernel";
            key = "│ ├ ";
            keyColor = "${base0D}";
          }
          {
            type = "packages";
            key = "│ ├󰏖 ";
            keyColor = "${base0D}";
          }
          {
            type = "shell";
            key = "│ ├ ";
            keyColor = "${base0D}";
          }
          {
            type = "terminal";
            key = "└ └ ";
            keyColor = "${base0D}";
          }
          {
            type = "custom";
            format = "└────────────────────────────────────────────────────┘";
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
          # "break"
          {
            type = "custom";
            format = "┌──────────────────────Network───────────────────────┐";
          }
          {
            type = "localip";
            key = "󰩟 IP";
            showIpv6 = false;
            showMac = false;
            keyColor = "${base07}";
            format = "{ifname}";
          }
          {
            type = "localip";
            key = "│ ├ ";
            showIpv6 = false;
            showMac = false;
            keyColor = "${base07}";
            format = "{ipv4} {ifname}";
          }
          {
            type = "publicip";
            timeout = 1000;
            key = "└ └ ";
            keyColor = "${base07}";
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