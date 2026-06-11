{
  config,
  ...
}:
let
  inherit (config.theme.colors)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
    base10
    base11
    base12
    base13
    base14
    base15
    base16
    base17
    ;
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
