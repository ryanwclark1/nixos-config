{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/rofi/style/launcher-long.rasi" = {
    text = ''

      /*****----- Configuration -----*****/
      configuration {
        modi:                       "drun";
        show-icons:                 true;
        display-drun:               "";
        drun-display-format:        "{name}";
      }

      /*****----- Global Properties -----*****/
      @import                          "shared/colors.rasi"
      @import                          "shared/fonts.rasi"

      /*****----- Main Window -----*****/
      window {
        transparency:                "real";
        location:                    west;
        anchor:                      west;
        fullscreen:                  false;
        width:                       450px;
        height:                      100%;
        x-offset:                    0px;
        y-offset:                    0px;

        enabled:                     true;
        margin:                      0px;
        padding:                     0px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            @background;
        cursor:                      "default";
      }

      /*****----- Main Box -----*****/
      mainbox {
        enabled:                     true;
        spacing:                     0px;
        margin:                      0px;
        padding:                     0px;
        border:                      0px solid;
        border-radius:               0px 0px 0px 0px;
        border-color:                @selected;
        background-color:            transparent;
        children:                    [ "inputbar", "listview" ];
      }

      /*****----- Inputbar -----*****/
      inputbar {
        enabled:                     true;
        spacing:                     10px;
        margin:                      0px;
        padding:                     12px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            @selected;
        text-color:                  @background;
        children:                    [ "prompt", "entry" ];
      }

      prompt {
        enabled:                     true;
        background-color:            inherit;
        text-color:                  inherit;
      }
      textbox-prompt-colon {
        enabled:                     true;
        expand:                      false;
        str:                         "::";
        background-color:            inherit;
        text-color:                  inherit;
      }
      entry {
        enabled:                     true;
        background-color:            inherit;
        text-color:                  inherit;
        cursor:                      text;
        placeholder:                 "Search...";
        placeholder-color:           inherit;
      }

      /*****----- Listview -----*****/
      listview {
        enabled:                     true;
        columns:                     1;
        lines:                       6;
        cycle:                       true;
        dynamic:                     true;
        scrollbar:                   false;
        layout:                      vertical;
        reverse:                     false;
        fixed-height:                true;
        fixed-columns:               true;

        spacing:                     5px;
        margin:                      0px;
        padding:                     0px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            transparent;
        text-color:                  @foreground;
        cursor:                      "default";
      }
      scrollbar {
        handle-width:                5px ;
        handle-color:                @selected;
        border-radius:               0px;
        background-color:            @background-alt;
      }

      /*****----- Elements -----*****/
      element {
        enabled:                     true;
        spacing:                     10px;
        margin:                      0px;
        padding:                     6px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            transparent;
        text-color:                  @foreground;
        cursor:                      pointer;
      }
      element normal.normal {
        background-color:            @background;
        text-color:                  @foreground;
      }
      element selected.normal {
        background-color:            @background-alt;
        text-color:                  @foreground;
      }
      element-icon {
        background-color:            transparent;
        text-color:                  inherit;
        size:                        32px;
        cursor:                      inherit;
      }
      element-text {
        background-color:            transparent;
        text-color:                  inherit;
        highlight:                   inherit;
        cursor:                      inherit;
        vertical-align:              0.5;
        horizontal-align:            0.0;
      }

      /*****----- Message -----*****/
      error-message {
        padding:                     15px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            @background;
        text-color:                  @foreground;
      }
      textbox {
        background-color:            @background;
        text-color:                  @foreground;
        vertical-align:              0.5;
        horizontal-align:            0.0;
        highlight:                   none;
      }
    '';
    executable = false;
  };
}
