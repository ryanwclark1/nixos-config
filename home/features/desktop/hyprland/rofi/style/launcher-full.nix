{
  config,
  lib,
  pkgs,
  ...
}:

with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

{
  home.file.".config/rofi/style/launcher-full.rasi" = {
    text = ''
      /*****----- Configuration -----*****/
      configuration {
        modi:                       "drun";
        show-icons:                 true;
        display-drun:               " ";
        drun-display-format:        "{name}";
      }

      /*****----- Global Properties -----*****/
      @import                          "shared/colors.rasi"
      @import                          "shared/fonts.rasi"


      /*****----- Main Window -----*****/
      window {
        transparency:                "real";
        location:                    center;
        anchor:                      center;
        fullscreen:                  true;
        x-offset:                    0px;
        y-offset:                    0px;
        enabled:                     true;
        margin:                      0px;
        padding:                     0px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            black / 50%;
        cursor:                      "default";
      }

      /*****----- Main Box -----*****/
      mainbox {
        enabled:                     true;
        spacing:                     100px;
        margin:                      0px;
        padding:                     100px 225px;
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
        margin:                      0% 25%;
        padding:                     18px;
        border:                      0px solid;
        border-radius:               10px;
        border-color:                @selected;
        background-color:            white / 5%;
        text-color:                  @foreground;
        children:                    [ "prompt", "entry" ];
      }

      prompt {
        enabled:                     true;
        background-color:            transparent;
        text-color:                  inherit;
      }
      textbox-prompt-colon {
        enabled:                     true;
        expand:                      false;
        str:                         "::";
        background-color:            transparent;
        text-color:                  inherit;
      }
      entry {
        enabled:                     true;
        background-color:            transparent;
        text-color:                  inherit;
        cursor:                      text;
        placeholder:                 "Search";
        placeholder-color:           inherit;
      }

      /*****----- Listview -----*****/
      listview {
        enabled:                     true;
        columns:                     8;
        lines:                       4;
        cycle:                       true;
        dynamic:                     true;
        scrollbar:                   false;
        layout:                      vertical;
        reverse:                     false;
        fixed-height:                true;
        fixed-columns:               true;

        spacing:                     0px;
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
        spacing:                     15px;
        margin:                      0px;
        padding:                     35px 10px;
        border:                      0px solid;
        border-radius:               15px;
        border-color:                @selected;
        background-color:            transparent;
        text-color:                  @foreground;
        orientation:                 vertical;
        cursor:                      pointer;
      }
      element normal.normal {
        background-color:            transparent;
        text-color:                  @foreground;
      }
      element selected.normal {
        background-color:            white / 5%;
        text-color:                  @foreground;
      }
      element-icon {
        background-color:            transparent;
        text-color:                  inherit;
        size:                        72px;
        cursor:                      inherit;
      }
      element-text {
        background-color:            transparent;
        text-color:                  inherit;
        highlight:                   inherit;
        cursor:                      inherit;
        vertical-align:              0.5;
        horizontal-align:            0.5;
      }

      /*****----- Message -----*****/
      error-message {
        padding:                     100px;
        border:                      0px solid;
        border-radius:               0px;
        border-color:                @selected;
        background-color:            black / 10%;
        text-color:                  @foreground;
      }
      textbox {
        background-color:            transparent;
        text-color:                  @foreground;
        vertical-align:              0.5;
        horizontal-align:            0.0;
        highlight:                   none;
      }
    '';
  executable = false;
  };
}