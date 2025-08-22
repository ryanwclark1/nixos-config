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
