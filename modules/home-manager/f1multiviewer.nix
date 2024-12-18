{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.f1multiviewer;
in {
  options.programs.f1multiviewer = {
    enable = mkEnableOption "F1 MultiViewer";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./f1multiviewer/default.nix {};
      defaultText = literalExpression "pkgs.f1multiviewer";
      description = "The F1 MultiViewer package to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Ensure XDG MIME type is registered
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/multiviewer" = [ "f1multiviewer.desktop" ];
      };
    };
  };
}