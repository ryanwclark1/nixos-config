final: prev: {
  uv = prev.uv.overrideAttrs (oldAttrs: {
    version = "0.5.10";
    src = prev.fetchFromGitHub {
      owner = "astral-sh";
      repo = "uv";
      rev = "refs/tags/${oldAttrs.version}";
      hash = "sha256-GE/MgaX6JhzVVwrkz33fr1Vl83QD1WHhlB7vPdJ2W3c=";
    };
    cargoDeps = prev.rustPlatform.fetchCargoTarball {
      inherit (oldAttrs) src;
      name = "uv-${oldAttrs.version}";
      hash = "sha256-GE/MgaX6JhzVVwrkz33fr1Vl83QD1WHhlB7vPdJ2W3c=";
    };
  });
}
