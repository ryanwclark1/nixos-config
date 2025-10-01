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
  # TODO: Fix colors with rgba
  home.file.".config/swaync/style.css" = {
    text = ''
    /* Colors */

    /*  @import '~/.cache/wal/colors-waybar.css'; */
    @define-color text #${base05};
    @define-color surface0 #${base02};
    @define-color surface1 #${base03};
    @define-color base #${base00};
    @define-color blue #${base0D};
    @define-color red #${base08};
    @define-color sapphire #${base16};
    @define-color yellow #${base0A};
    @define-color maroon #${base12};
    @define-color overlay0 #${base04};
    @define-color overlay1 #${base04};
    @define-color subtext0 #${base05};
    @define-color surface2 #${base04};
    @define-color crust #${base01};

    :root {
      --border-radius: 22px;
      --cc-bg: transparent;

      --widget-background: rgba(46, 46, 46, 0.7);
      --noti-bg-alpha: 0.6;

      --padding: calc(var(--border-radius) / 2);
    }

    .control-center {
      border-radius: 0;
    }

    .widgets > .widget,
    .widget-mpris > carouselindicatordots,
    .widget-mpris > box > button {
      background: var(--widget-background);
      border-radius: var(--border-radius);
      padding: calc(var(--border-radius) / 2);
      border: var(--border);
    }

    .control-center-list-placeholder {
      padding: var(--border-radius);
    }

    .notification-group {
      border-radius: var(--border-radius);
      padding: 8px;
    }

    .widget.widget-mpris {
      background: transparent;
      border-radius: 0;
      padding: 0;
      border: none;
    }
    .widget.widget-mpris > carouselindicatordots {
      --dots-padding: 4px;
      padding: var(--dots-padding);
      padding-left: var(--dots-padding);
      padding-right: calc(6px + var(--dots-padding));
      margin: 0;
      margin-top: var(--padding);
    }
    .widget-mpris > box > button:hover {
      background: rgba(46, 46, 46, 1);
    }
    .widget-mpris-player {
      box-shadow: none;
      border: var(--border);
      margin: 0 var(--padding);
    }
    .widget-mpris-player:only-child {
      margin: 0;
    }
    '';
  };
}
