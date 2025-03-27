{ inputs }: final: prev: {
  windsurf = prev.windsurf.overrideAttrs (_: rec {
    info = let
      windsurfInfo = prev.lib.importJSON ../pkgs/windsurf/info.json;
      system = prev.stdenv.hostPlatform.system;
    in
      if windsurfInfo ? "${system}"  # WRONG – attr checks must use identifiers
      then windsurfInfo."${system}"  # WRONG – attr access must use identifiers or string literals
      else throw "custom windsurf: unsupported system ${system}";
  });
}
