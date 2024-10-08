{
  config,
  pkgs,
  ...
}:

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
              fgColor = "#c6d0f5";
              bgColor = "default";
              logoColor = "#ca9ee6";
            };
            prompt = {
              fgColor = "#c6d0f5";
              bgColor = "default";
              suggestColor = "#8caaee";
            };
            info = {
              fgColor = "#ef9f76";
              sectionColor = "#c6d0f5";
            };
            dialog = {
              fgColor = "#e5c890";
              bgColor = "default";
              buttonFgColor = "#303446";
              buttonBgColor = "default";
              buttonFocusFgColor = "#303446";
              buttonFocusBgColor = "#f4b8e4";
              labelFgColor = "#f2d5cf";
              fieldFgColor = "#c6d0f5";
            };
            frame = {
              title = {
                fgColor = "#81c8be";
                bgColor = "default";
                highlightColor = "#f4b8e4";
                counterColor = "#e5c890";
                filterColor = "#a6d189";
              };
              border = {
                fgColor = "#ca9ee6";
                focusColor = "#babbf1";
              };
              menu = {
                fgColor = "#c6d0f5";
                keyColor = "#8caaee";
                numKeyColor = "#ea999c";
              };
              crumbs = {
                fgColor = "#303446";
                bgColor = "default";
                activeColor = "#eebebe";
              };
              status = {
                newColor = "#8caaee";
                modifyColor = "#babbf1";
                addColor = "#a6d189";
                pendingColor = "#ef9f76";
                errorColor = "#e78284";
                highlightColor = "#99d1db";
                killColor = "#ca9ee6";
                completedColor = "#737994";
              };
            };
            views = {
              table = {
                fgColor = "#c6d0f5";
                bgColor = "default";
                cursorFgColor = "#414559";
                cursorBgColor = "#51576d";
                markColor = "#f2d5cf";
                header = {
                  fgColor = "#e5c890";
                  bgColor = "default";
                  sorterColor = "#99d1db";
                };
              };
              xray = {
                fgColor = "#c6d0f5";
                bgColor = "default";
                cursorColor = "#51576d";
                cursorTextColor = "#303446";
                graphicColor = "#f4b8e4";
                showIcons = true;
              };
              charts = {
                bgColor = "default";
                chartBgColor = "default";
                dialBgColor = "default";
                defaultDialColors =[
                  "#a6d189"
                  "#e78284"
                ];
                defaultChartColors =[
                  "#a6d189"
                  "#e78284"
                ];
                resourceColors = {
                  cpu = [
                    "#ca9ee6"
                    "#8caaee"
                  ];
                  mem = [
                    "#e5c890"
                    "#ef9f76"
                  ];
                };
              };
              yaml = {
                keyColor = "#8caaee";
                valueColor = "#c6d0f5";
                colonColor = "#a5adce";
              };
              logs = {
                fgColor = "#c6d0f5";
                bgColor = "default";
                indicator = {
                  fgColor = "#babbf1";
                  bgColor = "default";
                  toggleOnColor = "#a6d189";
                  toggleOffColor = "#a5adce";
                };
              };
            };
            help = {
              fgColor = "#c6d0f5";
              bgColor = "default";
              sectionColor = "#a6d189";
              keyColor = "#8caaee";
              numKeyColor = "#ea999c";
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
