{

  ...
}:

{
  home.file.".config/rofi/style/shared/confirm.rasi" = {
    text = ''
      /*****----- Configuration -----*****/
      configuration {
          show-icons:                 false;
      }

      /*****----- Global Properties -----*****/
      @import                          "colors.rasi"
      @import                          "fonts.rasi"

      /*****----- Main Window -----*****/
      window {
          location:                    center;
          anchor:                      center;
          fullscreen:                  false;
          width:                       500px;
          border-radius:               20px;
          cursor:                      "default";
          background-color:            @background;
      }

      /*****----- Main Box -----*****/
      mainbox {
          spacing:                     30px;
          padding:                     30px;
          background-color:            transparent;
          children:                    [ "message", "listview" ];
      }

      /*****----- Message -----*****/
      message {
          margin:                      0px;
          padding:                     20px;
          border-radius:               20px;
          background-color:            @background-alt;
          text-color:                  @foreground;
      }
      textbox {
          background-color:            inherit;
          text-color:                  inherit;
          vertical-align:              0.5;
          horizontal-align:            0.5;
          placeholder-color:           @foreground;
          blink:                       true;
          markup:                      true;
      }

      /*****----- Listview -----*****/
      listview {
          columns:                     2;
          lines:                       1;
          cycle:                       true;
          dynamic:                     true;
          scrollbar:                   false;
          layout:                      vertical;
          reverse:                     false;
          fixed-height:                true;
          fixed-columns:               true;

          spacing:                     30px;
          background-color:            transparent;
          text-color:                  @foreground;
          cursor:                      "default";
      }

      /*****----- Elements -----*****/
      element {
          padding:                     60px 10px;
          border-radius:               20px;
          background-color:            @background-alt;
          text-color:                  @foreground;
          cursor:                      pointer;
      }
      element-text {
          font:                        "feather 48";
          background-color:            transparent;
          text-color:                  inherit;
          cursor:                      inherit;
          vertical-align:              0.5;
          horizontal-align:            0.5;
      }
      element selected.normal {
          background-color:            var(selected);
          text-color:                  var(background);
      }
    '';
    executable = false;
  };
}
