{ config, pkgs, lib, ... }:

let
  windsurfOverlay = final: prev: {
    windsurf = prev.windsurf.overrideAttrs (_: let
      info = (final.lib.importJSON ../../../pkgs/windsurf/info.json)."${final.stdenv.hostPlatform.system}"
        or (throw "custom windsurf: unsupported system ${final.stdenv.hostPlatform.system}");
    in {
      version = info.version;
      src = final.fetchurl {
        url = info.url;
        sha256 = info.sha256;
      };
    });
  };
in {
  nixpkgs = {
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "windsurf" ];
    overlays = [ windsurfOverlay ];
  };

  home.packages = with pkgs; [
    windsurf
  ];
}
