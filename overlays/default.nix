# This file defines overlays
{
  inputs,
  ...
}:

{
  # https://nixos.wiki/wiki/Overlays

  modifications = final: prev: {
    vscode = prev.vscode.overrideAttrs (_: rec {
      version = "1.89.0";
      plat = "linux-x64";
      archive_fmt = "tar.gz";
      pname = "vscode";
      src = prev.fetchurl {
        url = "https://update.code.visualstudio.com/${version}/${plat}/stable";
        sha256 = "sha256-vGDY57xMuEJrmJBwQ0ufnAKt1GR16jEDKt5/fva9wUM=";
        name = "VSCode_${version}_${plat}.${archive_fmt}";
      };
    });

    # When applied, the unstable nixpkgs set (declared in the flake inputs) will
    # be accessible through 'pkgs.unstable'
    unstable-packages = final: prev: {
      unstable = import inputs.nixpkgs {
        inherit (final) system;
        config.allowUnfree = true;
      };
    };
  };
}
