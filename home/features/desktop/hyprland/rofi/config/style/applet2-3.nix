{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/rofi/style/applet2-3.rasi" = {
    text = ''
      /*****----- Configuration -----*****/
      configuration {
        show-icons:                 false;
      }

      /*****----- Global Properties -----*****/
      @import                          "shared/colors.rasi"
      @import                          "shared/fonts.rasi"

      /*
      USE_ICON=YES
      */

      /*****----- Main Window -----*****/
      window {
        transparency:                "real";
        location:                    center;
        anchor:                      center;
        fullscreen:                  false;
        width:                       800px;
        x-offset:                    0px;
        y-offset:                    0px;
        margin:                      0px;
        padding:                     0px;
        border:                      0px solid;
        border-radius:               30px;
        border-color:                @selected;
        cursor:                      "default";
        background-color:            @background;
      }

      /*****----- Main Box -----*****/
      mainbox {
        enabled:                     true;
        spacing:                     15px;
        margin:                      0px;
        padding:                     30px;
        background-color:            transparent;
        children:                    [ "inputbar", "message", "listview" ];
      }

      /*****----- Inputbar -----*****/
      inputbar {
        enabled:                     true;
        spacing:                     10px;
        padding:                     0px;
        border:                      0px;
        border-radius:               100%;
        border-color:                @selected;
        background-color:            transparent;
        text-color:                  @foreground;
        children:                    [ "textbox-prompt-colon", "prompt"];
      }

      textbox-prompt-colon {
        enabled:                     true;
        expand:                      false;
        str:                         "";
        padding:                     10px 13px;
        border-radius:               100%;
        background-color:            @urgent;
        text-color:                  @background;
      }
      prompt {
        enabled:                     true;
        padding:                     10px;
        border-radius:               100%;
        background-color:            @active;
        text-color:                  @background;
      }

      /*****----- Message -----*****/
      message {
        enabled:                     true;
        margin:                      0px;
        padding:                     10px;
        border:                      0px solid;
        border-radius:               100%;
        border-color:                @selected;
        background-color:            @background-alt;
        text-color:                  @foreground;
      }
      textbox {
        background-color:            inherit;
        text-color:                  inherit;
        vertical-align:              0.5;
        horizontal-align:            0.0;
      }

      /*****----- Listview -----*****/
      listview {
        enabled:                     true;
        columns:                     6;
        lines:                       1;
        cycle:                       true;
        scrollbar:                   false;
        layout:                      vertical;

        spacing:                     15px;
        background-color:            transparent;
        cursor:                      "default";
      }

      /*****----- Elements -----*****/
      element {
        enabled:                     true;
        padding:                     30px 10px;
        border:                      0px solid;
        border-radius:               100%;
        border-color:                @selected;
        background-color:            transparent;
        text-color:                  @foreground;
        cursor:                      pointer;
      }
      element-text {
        font:                        "feather 28";
        background-color:            transparent;
        text-color:                  inherit;
        cursor:                      inherit;
        vertical-align:              0.5;
        horizontal-align:            0.5;
      }

      element normal.normal,
      element alternate.normal {
        background-color:            var(background-alt);
        text-color:                  var(foreground);
      }
      element normal.urgent,
      element alternate.urgent,
      element selected.active {
        background-color:            var(urgent);
        text-color:                  var(background);
      }
      element normal.active,
      element alternate.active,
      element selected.urgent {
        background-color:            var(active);
        text-color:                  var(background);
      }
      element selected.normal {
        background-color:            var(selected);
        text-color:                  var(background);
      }
      '';
    executable = false;
  };
}
