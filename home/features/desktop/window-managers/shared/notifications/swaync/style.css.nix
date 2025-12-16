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
      --radius: 22px;
      --gap: 12px;

      --cc-bg: rgba(30, 30, 46, 0.75);
      --popup-bg: rgba(30, 30, 46, 0.65);
      --card-bg: rgba(46, 46, 46, 0.7);
    }

    /* =========================
    POPUP NOTIFICATIONS
    ========================= */

    .notification-window {
      background: transparent;
    }

    .notification {
      background: var(--popup-bg);
      margin: var(--gap) 0;
      padding: 14px;
      border-radius: var(--radius);
    }

    .notification-content {
      spacing: 10px;
    }

    .notification-title {
      font-weight: bold;
      color: @text;
    }

    .notification-body {
      color: @text;
      opacity: 0.9;
    }

    /* =========================
      CONTROL CENTER
      ========================= */

    .control-center {
      background: var(--cc-bg);
      border-radius: var(--radius);
      padding: var(--gap);
      backdrop-filter: blur(20px); 
    }

    .widgets {
      spacing: var(--gap);
    }

    /* Widget cards */
    .widgets > .widget {
      background: var(--card-bg);
      padding: var(--gap);
      border-radius: var(--radius);
    }

    /* =========================
      TITLE WIDGET
      ========================= */

    .widget-title {
      padding-bottom: 6px;
    }

    .widget-title button {
      background: @surface0;
      border-radius: 999px;
    }

    /* =========================
      BUTTON GRID
      ========================= */

    .widget-buttons-grid button {
      min-width: 42px;
      min-height: 42px;
      border-radius: 999px;
    }

    /* =========================
      MPRIS
      ========================= */

    .widget-mpris {
      background: transparent;
      padding: 0;
    }

    .widget-mpris-player {
      background: var(--card-bg);
      border-radius: var(--radius);
      padding: var(--gap);
    }

    /* =========================
      VOLUME
      ========================= */

    .widget-volume row {
      padding: 6px 0;
    }

    /* =========================
      NOTIFICATIONS LIST
      ========================= */

    .notification-group {
      background: transparent;
      padding: 0;
    }

    .notification-group > .notification {
      margin-bottom: var(--gap);
    }
    '';
  };
}
