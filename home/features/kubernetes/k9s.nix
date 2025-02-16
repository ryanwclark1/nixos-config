{
  config,
  pkgs,
  ...
}:
# Non variable colors are from https://catppuccin.com/palette
let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in
{
  programs = {
    k9s = {
      enable = true;
      package = pkgs.k9s;
      aliases = {
        aliases = {
          # Use pp as an alias for Pod
          pp = "v1/pods";
        };
      };
      hotkey = {
        # Make sure this is camel case
        hotKeys = {
          shift-0 = {
            shortCut = "Shift-0";
            description = "Viewing pods";
            command = "pods";
          };
        };
      };
      plugin = {
        # Defines a plugin to provide a `ctrl-l` shortcut to
        # tail the logs while in pod view.
        fred = {
          shortCut = "Ctrl-L";
          description = "Pod logs";
          scopes = [ "po" ];
          command = "kubectl";
          background = false;
          args = [
            "logs"
            "-f"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CLUSTER"
          ];
        };
        # Manage cert-manager Certificate resouces via cmctl.
        # See: https://github.com/cert-manager/cmctl
        cert-status = {
          shortCut = "Shift-S";
          confirm = false; description = "Certificate status";
          scopes = [ "certificates" ];
          command = "bash";
          background = false;
          args = [ "-c" "cmctl status certificate --context $CONTEXT -n $NAMESPACE $NAME |& less" ];
        };
        cert-renew = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Certificate renew";
          scopes = [ "certificates" ];
          command = "bash";
          background = false;
          args = [ "-c" "cmctl renew --context $CONTEXT -n $NAMESPACE $NAME |& less" ];
        };
        secret-inspect = {
          shortCut = "Shift-I";
          confirm = false;
          description = "Inspect secret";
          scopes = [ "secrets" ];
          command = "bash";
          background = false;
          args = [ "-c" "cmctl inspect secret --context $CONTEXT -n $NAMESPACE $NAME |& less" ];
        };
      };
      skins = {
        default_skin = {
          k9s = {
            body = {
              fgColor = "#${base05}";
              bgColor = "default";
              logoColor = "#${base0E}";
            };
            prompt = {
              fgColor = "#${base05}";
              bgColor = "default";
              suggestColor = "#${base0D}";
            };
            info = {
              fgColor = "#${base09}";
              sectionColor = "#${base05}";
            };
            dialog = {
              fgColor = "#${base0A}";
              bgColor = "default";
              buttonFgColor = "#${base00}";
              buttonBgColor = "default";
              buttonFocusFgColor = "#${base00}";
              buttonFocusBgColor = "#${base17}";
              labelFgColor = "#${base13}";
              fieldFgColor = "#${base05}";
            };
            frame = {
              title = {
                fgColor = "#${base0C}";
                bgColor = "default";
                highlightColor = "#${base17}";
                counterColor = "#${base0A}";
                filterColor = "#${base0B}";
              };
              border = {
                fgColor = "#${base0E}";
                focusColor = "#${base07}";
              };
              menu = {
                fgColor = "#${base05}";
                keyColor = "#${base0D}";
                numKeyColor = "#${base12}";
              };
              crumbs = {
                fgColor = "#${base00}";
                bgColor = "default";
                activeColor = "#${base0F}";
              };
              status = {
                newColor = "#${base0D}";
                modifyColor = "#${base07}";
                addColor = "#${base0B}";
                pendingColor = "#${base09}";
                errorColor = "#${base08}";
                highlightColor = "#${base15}";
                killColor = "#${base0E}";
                completedColor = "#737994";
              };
            };
            views = {
              table = {
                fgColor = "#${base05}";
                bgColor = "default";
                cursorFgColor = "#${base02}";
                cursorBgColor = "#${base03}";
                markColor = "#${base13}";
                header = {
                  fgColor = "#${base0A}";
                  bgColor = "default";
                  sorterColor = "#${base15}";
                };
              };
              xray = {
                fgColor = "#${base05}";
                bgColor = "default";
                cursorColor = "#${base03}";
                cursorTextColor = "#${base00}";
                graphicColor = "#${base17}";
                showIcons = true;
              };
              charts = {
                bgColor = "default";
                chartBgColor = "default";
                dialBgColor = "default";
                defaultDialColors =[
                  "#${base0B}"
                  "#${base08}"
                ];
                defaultChartColors =[
                  "#${base0B}"
                  "#${base08}"
                ];
                resourceColors = {
                  cpu = [
                    "#${base0E}"
                    "#${base0D}"
                  ];
                  mem = [
                    "#${base0A}"
                    "#${base09}"
                  ];
                };
              };
              yaml = {
                keyColor = "#${base0D}";
                valueColor = "#${base05}";
                colonColor = "#a5adce";
              };
              logs = {
                fgColor = "#${base05}";
                bgColor = "default";
                indicator = {
                  fgColor = "#${base07}";
                  bgColor = "default";
                  toggleOnColor = "#${base0B}";
                  toggleOffColor = "#a5adce";
                };
              };
            };
            help = {
              fgColor = "#${base05}";
              bgColor = "default";
              sectionColor = "#${base0B}";
              keyColor = "#${base0D}";
              numKeyColor = "#${base12}";
            };
          };
        };
      };
      settings = {
        k9s ={
          skin = "default_skin";
          liveViewAutoRefresh = true;
          screenDumpDir = "${config.home.homeDirectory}/.local/state/k9s/screen-dumps";
          refreshRate = 2;
          maxConnRetry = 5;
          readOnly = false;
          noExitOnCtrlC = false;
          ui = {
            enableMouse = false;
            headless = false;
            logoless = false;
            crumbsless = false;
            reactive = true;
            noIcons = false;
            defaultsToFullScreen = false;
          };
          skipLatestRevCheck = false;
          disablePodCounting = false;
          shellPod = {
            image = "busybox:1.37.0";
            namespace = "default";
            limits = {
              cpu = "100m";
              memory = "100Mi";
            };
          };
          imageScans = {
            enable = true;
            exclusions = {
              namespaces = [];
              labels = {};
            };
          };
          logger = {
            tail = 100;
            buffer = 5000;
            sinceSeconds = -1;
            textWrap = false;
            showTime = false;
          };
          thresholds = {
            cpu = {
              critical = 90;
              warn = 70;
            };
            memory = {
              critical = 90;
              warn = 70;
            };
          };
        };
      };
    };
  };
}
