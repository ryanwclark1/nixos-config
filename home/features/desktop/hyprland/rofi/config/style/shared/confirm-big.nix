{
  ...
}:

{
  home.file.".config/rofi/style/shared/confirm-big.rasi" = {
    text = ''
      /*****----- Configuration -----*****/
      configuration {
        show-icons: false;
      }

      /*****----- Global Properties -----*****/
      @import                          "colors.rasi"
      @import                          "fonts.rasi"

      /*****----- Global Properties -----*****/
      * {
        mainbox-spacing: 50px;
        mainbox-margin: 0px 30%;
        message-margin: 0px 10%;
        message-padding: 15px;
        message-border-radius: 15px;
        listview-spacing: 25px;
        element-padding: 35px 40px;
        element-border-radius: 20px;

        prompt-font: "${config.stylix.fonts.monospace.name} Bold Italic 64";
        textbox-font: "${config.stylix.fonts.monospace.name} 16";
        element-icon-font: "feather 64"; /* Larger font for icons */
        element-text-font: "feather 64"; /* Smaller font for text */

        background-window: black/70%;
        background-normal: white/5%;
        background-selected: white/15%;
        foreground-normal: @foreground;
      }

      /*****----- Main Window -----*****/
      window {
        transparency: "real";
        location: center;
        anchor: center;
        fullscreen: true;
        cursor: "default";
        background-color: var(background-window);
      }

      /*****----- Main Box -----*****/
      mainbox {
        enabled: true;
        spacing: var(mainbox-spacing);
        margin: var(mainbox-margin);
        background-color: transparent;
        children: ["dummy", "inputbar", "listview", "message", "dummy"];
      }

      /*****----- Inputbar -----*****/
      inputbar {
        enabled: true;
        background-color: transparent;
        children: ["dummy", "prompt", "dummy"];
      }

      dummy {
        background-color: transparent;
      }

      prompt {
        enabled: true;
        font: var(prompt-font);
        background-color: transparent;
        text-color: var(foreground);
      }

      /*****----- Message -----*****/
      message {
        enabled: true;
        margin: var(message-margin);
        padding: var(message-padding);
        border-radius: var(message-border-radius);
        background-color: var(background-normal);
        text-color: var(foreground);
      }
      textbox {
        font: var(textbox-font);
        background-color: transparent;
        text-color: inherit;
        vertical-align: 0.5;
        horizontal-align: 0.5;
      }

      /*****----- Listview -----*****/
      listview {
        enabled: true;
        expand: false;
        columns: 2;
        lines: 1;
        cycle: true;
        dynamic: true;
        scrollbar: false;
        layout: vertical;
        reverse: false;
        fixed-height: true;
        fixed-columns: true;

        spacing: var(listview-spacing);
        background-color: transparent;
        cursor: "default";
      }

      /*****----- Elements -----*****/
      element {
        enabled: true;
        padding: var(element-padding);
        border-radius: var(element-border-radius);
        background-color: var(background-normal);
        text-color: var(foreground);
        cursor: pointer;
        layout: vertical; /* Stack icon and text vertically */
      }
      element-icon {
        font: var(element-icon-font); /* Font size for icons */
        text-color: inherit;
        vertical-align: 0.5;
        horizontal-align: 0.5;
        margin-bottom: 10px; /* Space between icon and text */
      }
      element-text {
        font: var(element-text-font); /* Smaller font for text */
        background-color: transparent;
        text-color: inherit;
        cursor: inherit;
        vertical-align: 0.5;
        horizontal-align: 0.5;
      }
      element selected.normal {
        background-color: var(background-selected);
        text-color: var(selected);
      }
    '';
    executable = false;
  };
}
