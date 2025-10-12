# overlays/goose-bump.nix
final: prev:
let
  lib = final.lib;

  # <<< pick the version you want >>>
  newVersion = "1.9.3";

  overrideGoose = old:
    old.overrideAttrs (_final: super: {
      version = newVersion;

      src = prev.fetchFromGitHub {
        owner = "block";
        repo  = "goose";
        tag   = "v${newVersion}";
        # First run: use fakeHash and let Nix tell you the real one
        hash  = lib.fakeHash;
      };

      # First run: use fakeHash; Nix will print the correct cargoHash
      cargoHash = lib.fakeHash;
    });
in
  # Apply to whichever attribute exists in your pinned nixpkgs
  lib.optionalAttrs (prev ? goose) { goose = overrideGoose prev.goose; }
  //
  lib.optionalAttrs (prev ? goose-cli) { goose-cli = overrideGoose prev."goose-cli"; }
