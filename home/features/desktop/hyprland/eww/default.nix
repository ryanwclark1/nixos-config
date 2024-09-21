# TODO: Configure XDG_CONFIG_HOME for config directory
{ inputs, lib, config, pkgs, ... }:
let
  user = "administrator";
  homeDirectory = "/home/${user}/.config";
in
{
    programs = {
        eww = {
            enable = true;
            package = pkgs.eww;
            enableZshIntegration = true;
            enableBashIntegration = true;
            enableFishIntegration = true;
            # configDir = "${XDG_CONFIG_HOME}/eww";
            # configDir = "${homeDirectory}/eww";
        };
    };

    # home.packages = with pkgs; [
    #     brightnessctl
    #     (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    # ];

    # configuration
    # home.file.".config/eww/eww.scss".source = ./eww.scss;
    # home.file.".config/eww/eww.yuck".source = ./eww.yuck;

    # # scripts
    # home.file.".config/eww/scripts" = {
    #     source = ./scripts;
    #     recursive = true;
    # };

    # home.file.".config/eww/scripts/battery.sh" = {
    #     source = ./scripts/battery.sh;
    #     executable = true;
    # };

    # home.file.".config/eww/scripts/wifi.sh" = {
    #     source = ./scripts/wifi.sh;
    #     executable = true;
    # };

    # home.file.".config/eww/scripts/brightness.sh" = {
    #     source = ./scripts/brightness.sh;
    #     executable = true;
    # };

    # home.file.".config/eww/scripts/workspaces.sh" = {
    #     source = ./scripts/workspaces.sh;
    #     executable = true;
    # };

    # home.file.".config/eww/scripts/workspaces.lua" = {
    #     source = ./scripts/workspaces.lua;
    #     executable = true;
    # };
}
