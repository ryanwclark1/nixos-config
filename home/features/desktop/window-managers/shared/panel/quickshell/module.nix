# Structured Home Manager module for Quickshell panel.
# Usage:
#   programs.quickshell-panel = {
#     enable = true;
#     config = { barHeight = 42; blurEnabled = false; };
#     features.ai.enable = true;
#   };
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.quickshell-panel;
  jsonFormat = pkgs.formats.json {};
in
{
  options.programs.quickshell-panel = {
    enable = lib.mkEnableOption "Quickshell panel";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "The Quickshell package to use.";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        Settings merged into Quickshell's config.json.
        Keys correspond to the Config.qml property names.
        Example: { barHeight = 42; blurEnabled = false; }
      '';
      example = {
        barHeight = 42;
        blurEnabled = false;
        timeUse24Hour = true;
      };
    };

    features = {
      ai = {
        enable = lib.mkEnableOption "AI chat feature";
      };
      wallhaven = {
        enable = lib.mkEnableOption "Wallhaven wallpaper browser";
      };
      lockScreen = {
        enable = lib.mkEnableOption "Lock screen" // { default = true; };
      };
    };

    systemd = {
      enable = lib.mkEnableOption "systemd user service" // { default = true; };
      restartIfChanged = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to restart the service on config change.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Activate the underlying feature module which handles packages,
    # file deployment, and systemd services.
    features.quickshell.enable = true;

    # Deploy merged config.json if user provided any settings
    home.file.".local/state/quickshell/config.json" = lib.mkIf (cfg.config != {}) {
      source = jsonFormat.generate "quickshell-config.json" cfg.config;
    };

    # Merge feature toggles into the config
    programs.quickshell-panel.config = lib.mkMerge [
      (lib.mkIf (!cfg.features.ai.enable) {
        enabledPanels = lib.mkDefault [
          "notifCenter" "controlCenter" "notepad" "commandPalette"
          "powerMenu" "colorPicker" "displayConfig" "fileBrowser" "systemMonitor"
        ];
      })
    ];
  };
}
