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

  programs =
    let
      inherit (config.theme.formats.base24.ansiRgb)
        base07
        base0C
        base0D
        base0E
        ;
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
            color = {
              "1" = "${base0D}";
              "2" = "${base07}";
            };
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
              format = "└───────────────────────────────────────────────────┘";
            }
            {
              type = "custom";
              format = "┌─────────────────────Network───────────────────────┐";
            }
            {
              type = "localip";
              key = "󰩟 IP";
              showIpv6 = false;
              showMac = false;
              keyColor = "${base0C}";
              format = "{ifname}";
            }
            {
              type = "localip";
              key = "│ ├ ";
              showIpv6 = false;
              showMac = false;
              keyColor = "${base0C}";
              format = "{ipv4} {ifname}";
            }
            {
              type = "publicip";
              timeout = 1000;
              key = "└ └ ";
              keyColor = "${base0C}";
            }
            {
              type = "custom";
              format = "└───────────────────────────────────────────────────┘";
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
