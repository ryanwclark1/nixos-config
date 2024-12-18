# { inputs, outputs }: final: prev: {
#   uv = prev.uv.overrideAttrs (_: rec {

#     version = "0.5.8";
#     platform = "x86_64-unknown-linux-gnu";

#     src = prev.fetchFromGitHub {
#       owner = "astral-sh";
#       repo = "uv";
#       tag = "${version}";
#       hash = "sha256-GE/MgaX6JhzVVwrkz33fr1Vl83QD1WHhlB7vPdJ2W3c=";
#     };

#     cargoDeps = prev.rustPlatform.fetchCargoTarball {
#       inherit src;
#       name = "${version}.tar.gz";
#       hash = "sha256-GE/MgaX6JhzVVwrkz33fr1Vl83QD1WHhlB7vPdJ2W3c=";
#     };
#   });
# }