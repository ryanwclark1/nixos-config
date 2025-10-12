# overlays/goose-bump.nix
# FIX: use prev.lib, not final.lib, to avoid infinite recursion

final: prev:
let
  lib = prev.lib;

  newVersion = "1.9.3";
in
{
  goose-cli = prev.goose-cli.overrideAttrs (_: super: {
    version = newVersion;

    src = prev.fetchFromGitHub {
      owner = "block";
      repo  = "goose";
      tag   = "v${newVersion}";
      # This is the *source* tarball hash you showed earlier:
      hash  = "sha256-cw4iGvfgJ2dGtf6om0WLVVmieeVGxSPPuUYss1rYcS8=";
    };

    cargoSha256 = "";
    # Leave empty once, build to learn the vendor hash, then paste it
    cargoHash = lib.fakeHash;
  });
}
