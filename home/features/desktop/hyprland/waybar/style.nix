{
  ...
}:
let
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
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
  home.file.".config/waybar/style.css" = {
    text = ''
      @define-color backgrounddark1 #${base00};
      @define-color backgrounddark2 #${base01};
      @define-color backgrounddark3 #${base02};
      @define-color workspacesbackground1 #FFFFFF;
      @define-color workspacesbackground2 #CCCCCC;
      @define-color bordercolor #FFFFFF;
      @define-color textcolor1 #${base05};
      @define-color textcolor2 #${base00};
      @define-color textcolor3 #FFFFFF;
      @define-color iconcolor #${base0E};

      /* Global Styles */
      * {
          font-size: 16px;
          font-family: DejaVu Sans, UbuntuMono Nerd Font;
          font-weight: bold;
      }

      /* -----------------------------------------------------
      * Window
      * ----------------------------------------------------- */
      window#waybar {
        background-color: @backgrounddark1;
        opacity: 0.75;
        color: @textcolor1;
        border-bottom: 0;
        transition: background-color 0.5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      window#waybar.empty #window {
        background-color: transparent;
      }

      /* -----------------------------------------------------
      * Module Group
      * ----------------------------------------------------- */
      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0 10px;
        border-radius: 0;
      }

      .modules-left > widget:first-child > #workspaces,
      .modules-right > widget:last-child > #workspaces {
        margin: 10px;
      }

      /* -----------------------------------------------------
      * Modules
      * ----------------------------------------------------- */
      #custom-applauncher {
        font-size: 22px;
        padding-right: 10px;
      }

      #hyprland-workspaces {
        padding-left: 1px;
        padding-right: 1px;
        /* justify-content: center; */
      }

      #workspaces button {
        min-width: 5px;
        color: @textcolor1;
        transition: ${betterTransition};
      }

      /* Hover and active states for buttons can be combined */
      #workspaces button.active,
      #workspaces button.hover {
        color: @textcolor1;
      }

      /* -----------------------------------------------------
      * Tooltips
      * ----------------------------------------------------- */
      tooltip {
        border-radius: 10px;
        background-color: @backgrounddark2;
        opacity: 0.8;
        padding: 20px;
      }

      tooltip label {
        color: @textcolor1;
      }

      /* General styles for multiple IDs */
      #custom-exit,
      #custom-hyprbindings,
      #battery,
      #custom-system,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd,
      #custom-speaker,
      #custom-mic,
      #clock,
      #bluetooth,
      #custom-nix-updates,
      #custom-cliphist,
      #group-hardware,
      #disk,
      #cpu,
      #memory,
      #custom-gpu {
        margin: 0;
        padding: 0 10px;
        color: @textcolor1;
        font-size: 14px;
      }

      /* Specific font sizes */
      #battery.icon,
      #network.icon,
      #bluetooth,
      #custom-nix-updates,
      #custom-hyprbindings,
      #custom-cliphist,
      #group-hardware {
        font-size: 16px;
        font-weight: bold;
      }

      #disk {
        font-size: 13px;
      }

      /* Additional margin for custom-exit */
      #custom-exit {
          padding-right: 15px;
      }
    '';
    executable = false;
  };
}
