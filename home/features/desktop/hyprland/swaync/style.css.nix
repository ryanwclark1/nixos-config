{
  ...
}:

{
  home.file.".config/swaync/style.css" = {
    text = ''
    /* Colors */

    @import '~/.cache/wal/colors-waybar.css';
    @define-color background #242424;
    @define-color groupbackground #363636;
    @define-color buttoncolor #4a4a4a;
    @define-color bordercolor @color11;
    @define-color fontcolor #FFFFFF;

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