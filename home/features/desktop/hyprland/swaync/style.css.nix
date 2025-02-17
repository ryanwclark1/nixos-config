{
  ...
}:
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
  home.file.".config/swaync/style.css" = {
    text = ''
    /* Colors */

    @import '~/.cache/wal/colors-waybar.css';
    @define-color background #${base00};
    @define-color groupbackground #363636;
    @define-color buttoncolor #4a4a4a;
    @define-color bordercolor #${base0E};
    @define-color fontcolor #${base05};

    * {
        font-family: "Fira Sans Semibold";
    }

    /* Control Center */

    .control-center {
        border: 3px solid @bordercolor;
        padding: 10px;
    }

    button {
        border: 0px;
        min-width: 35px;
        background: @buttoncolor;
    }

    .notification-group-header {
        font-size: 14px;
    }

    .widget-buttons-grid > flowbox > flowboxchild > button {
        margin:5px;
    }

    /* Notification */

    .notification {
        border: 3px solid @bordercolor;
      border-radius: 10px;
        padding:10px;
    }

    .notification-default-action:hover,
    .notification-action:hover {
        color: #ffffff;
        background: transparent;
    }

    '';
  };
}