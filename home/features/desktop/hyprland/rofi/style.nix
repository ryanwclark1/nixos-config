{
  config,
  lib,
  pkgs,
  ...
}:

with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

{
  home =
  let
    font = "${monospace.name} 12";
    background = "${base00}";
    # style_dir = "${config.xdg.configHome}/rofi/style";
  in
  {
    file.".config/rofi/style/cliphist.rasi" = {
      text = ''
        /*
        TEST-Font - ${font}
        TEST-Background - ${background}
        */

        /*****----- Global Properties -----*****/
        @import                          "shared/colors.rasi"
        @import                          "shared/fonts.rasi"
        @import                          "shared/border.rasi"

        /* ---- Configuration ---- */
        configuration {
          modi:                       "drun,run";
          show-icons:                 false;
          display-drun:               "APPS";
          display-run:                "RUN";
          display-filebrowser:        "FILES";
          display-window:             "WINDOW";
          hover-select:               true;
          me-select-entry:            "";
          me-accept-entry:            "MousePrimary";
          drun-display-format:        "{name}";
          window-format:              "{w} · {c} · {t}";
        }

        /* ---- Window ---- */
        window {
          width:                        600px;
          x-offset:                     0px;
          y-offset:                     0px;
          spacing:                      0px;
          padding:                      0px;
          margin:                       0px;
          color:                        #FFFFFF;
          border:                       @border-width;
          border-color:                 #FFFFFF;
          cursor:                       "default";
          transparency:                 "real";
          location:                     northeast;
          anchor:                       northeast;
          fullscreen:                   false;
          enabled:                      true;
          border-radius:                10px;
          background-color:             transparent;
        }

        /* ---- Mainbox ---- */
        mainbox {
          enabled:                      true;
          orientation:                  horizontal;
          spacing:                      0px;
          margin:                       0px;
          background-color:             @background;
          children:                     ["listbox"];
        }

        /* ---- Imagebox ---- */
        imagebox {
          padding:                      18px;
          background-color:             transparent;
          orientation:                  vertical;
          children:                     [ "inputbar", "dummy", "mode-switcher" ];
        }

        /* ---- Listbox ---- */
        listbox {
          spacing:                     20px;
          background-color:            transparent;
          orientation:                 vertical;
          children:                    [ "inputbar", "message", "listview" ];
        }

        /* ---- Dummy ---- */
        dummy {
          background-color:            transparent;
        }

        /* ---- Inputbar ---- */
        inputbar {
          enabled:                      true;
          text-color:                   @foreground;
          spacing:                      10px;
          padding:                      15px;
          border-radius:                0px;
          border-color:                 @foreground;
          background-color:             @background;
          children:                     [ "textbox-prompt-colon", "entry" ];
        }

        textbox-prompt-colon {
          enabled:                      true;
          expand:                       false;
          padding:                      0px 5px 0px 0px;
          str:                          " ";
          background-color:             transparent;
          text-color:                   inherit;
        }

        entry {
          enabled:                      true;
          background-color:             transparent;
          text-color:                   inherit;
          cursor:                       text;
          placeholder:                  "Search";
          placeholder-color:            inherit;
        }

        /* ---- Mode Switcher ---- */
        mode-switcher{
          enabled:                      true;
          spacing:                      20px;
          background-color:             transparent;
          text-color:                   @foreground;
        }

        button {
          padding:                      10px;
          border-radius:                10px;
          background-color:             @background;
          text-color:                   inherit;
          cursor:                       pointer;
          border:                       0px;
        }

        button selected {
          background-color:             @selected;
          text-color:                   @foreground;
        }

        /* ---- Listview ---- */
        listview {
          enabled:                      true;
          columns:                      1;
          lines:                        16;
          cycle:                        true;
          dynamic:                      true;
          scrollbar:                    false;
          layout:                       vertical;
          reverse:                      false;
          fixed-height:                 true;
          fixed-columns:                true;
          spacing:                      0px;
          padding:                      10px;
          margin:                       0px;
          background-color:             @background;
          border:0px;
        }

        /* ---- Element ---- */
        element {
          enabled:                      true;
          padding:                      10px;
          margin:                       5px;
          cursor:                       pointer;
          background-color:             @background;
          border-radius:                10px;
          border:                       @border-width;
        }

        element normal.normal {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element normal.urgent {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element normal.active {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element selected.normal {
          background-color:            @background;
          text-color:                  @foreground;
        }

        element selected.urgent {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element selected.active {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element alternate.normal {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element alternate.urgent {
          background-color:            inherit;
          text-color:                  @foreground;
        }

        element alternate.active {
          background-color:            inherit;
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
          cursor:                      inherit;
          vertical-align:              0.5;
          horizontal-align:            0.0;
        }

        /*****----- Message -----*****/
        message {
          background-color:            transparent;
          border:0px;
          margin:20px 0px 0px 0px;
          padding:0px;
          spacing:0px;
          border-radius: 10px;
        }

        textbox {
          padding:                     15px;
          margin:                      0px;
          border-radius:               0px;
          background-color:            @background;
          text-color:                  @foreground;
          vertical-align:              0.5;
          horizontal-align:            0.0;
        }

        error-message {
          padding:                     15px;
          border-radius:               20px;
          background-color:            @background;
          text-color:                  @foreground;
        }
      '';
      executable = false;
    };
  };
}