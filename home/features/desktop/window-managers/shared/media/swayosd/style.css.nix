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
  home.file.".config/swayosd/style.css" = {
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

      window {
        background-color: rgba(40, 42, 54, 0.9);
        border-radius: 20px;
        border: 2px solid rgba(98, 114, 164, 0.8);
        padding: 20px;
        margin: 20px;
        /* Center the window */
        margin-left: auto;
        margin-right: auto;
        margin-top: auto;
        margin-bottom: auto;
      }

      #container {
        /* Increase overall size */
        min-width: 400px;
        min-height: 120px;
        padding: 20px;
      }

      image {
        /* Make icon larger */
        min-width: 80px;
        min-height: 80px;
        margin-right: 20px;
      }

      progressbar, scale {
        /* Make progress bar larger */
        min-height: 20px;
        min-width: 300px;
      }

      progressbar trough {
        background-color: rgba(68, 71, 90, 0.8);
        border-radius: 10px;
        min-height: 20px;
      }

      progressbar progress {
        background-color: rgba(139, 233, 253, 0.9);
        border-radius: 10px;
        min-height: 20px;
      }

      label {
        /* Make text larger */
        font-size: 18px;
        font-weight: bold;
        color: rgba(248, 248, 242, 0.9);
        margin: 10px;
      }
    '';
  };
}
