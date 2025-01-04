{
  config,
  lib,
  pkgs,
  ...
}:
let
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
in
{
  home.file.".config/waybar/style.css" = {
    text = ''
      @define-color backgrounddark1 ${config.lib.stylix.colors.withHashtag.base00};
      @define-color backgrounddark2 ${config.lib.stylix.colors.withHashtag.base01};
      @define-color backgrounddark3 ${config.lib.stylix.colors.withHashtag.base02};
      @define-color workspacesbackground1 #FFFFFF;
      @define-color workspacesbackground2 #CCCCCC;
      @define-color bordercolor #FFFFFF;
      @define-color textcolor1 ${config.lib.stylix.colors.withHashtag.base07};
      @define-color textcolor2 ${config.lib.stylix.colors.withHashtag.base00};
      @define-color textcolor3 #FFFFFF;
      @define-color iconcolor ${config.lib.stylix.colors.withHashtag.base0E};

      /* Global Styles */
      * {
          font-size: 14px;
          font-family: ${config.stylix.fonts.sansSerif.name}, ${config.stylix.fonts.monospace.name};
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
