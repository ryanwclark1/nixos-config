{ inputs }: final: prev: {
  windsurf = prev.vscode.overrideAttrs (_: rec {
    info = (prev.lib.importJSON ../pkgs/windsurf/info.json)."${prev.stdenv.hostPlatform.system}"
      or (throw "custom windsurf: unsupported system ${prev.stdenv.hostPlatform.system}");
  });
}
