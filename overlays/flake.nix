# This file defines overlays
{
  inputs,
  ...
}:

{
  # https://nixos.wiki/wiki/Overlays

  modifications = final: prev: {

    uv = prev.uv.overrideAttrs (_: rec {
      version = "0.5.10";
      src = prev.fetchFromGitHub {
        owner = "astral-sh";
        repo = "uv";
        rev = "refs/tags/${version}";
        hash = "sha256-GE/MgaX6JhzVVwrkz33fr1Vl83QD1WHhlB7vPdJ2W3c=";
      };
      cargoDeps = prev.rustPlatform.fetchCargoTarball {
        inherit src;
        name = "uv-${version}";
        hash = "sha256-GE/MgaX6JhzVVwrkz33fr1Vl83QD1WHhlB7vPdJ2W3c=";
      };
    });

  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: prev: {
    unstable = import inputs.nixpkgs {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

}
