{
  lib,
  pkgs,
  ...
}:

{

  imports = [
    ./build.nix
    # ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./js.nix
    ./lua.nix
    ./protobuf.nix
    # ./python.nix
    # ./rust.nix
    ./sql.nix
  ];

  nixpkgs.overlays = [
    (
      final: prev: {
        uv = prev.uv.overrideAttrs (_: rec {
        version = "0.5.8";

        src = prev.fetchFromGitHub {
          owner = "astral-sh";
          repo = "uv";
          rev = "refs/tags/${version}";
          hash = "sha256-abJKfjEk8Ub0e4dtGTqEzx8UmB0a5LRnUgKI+PwyWJs=";
        };

        cargoDeps = prev.rustPlatform.importCargoLock {
          lockFile = prev.fetchurl {
            url = "https://raw.githubusercontent.com/astral-sh/uv/${version}/Cargo.lock";
            hash = "sha256-yeEbTSYU1xTB7HquqR7ltkVqjj6NVw5gT1e2K/iIFt0=";
          };
          outputHashes = {
            "async_zip-0.0.17" = "sha256-VfQg2ZY5F2cFoYQZrtf2DHj0lWgivZtFaFJKZ4oyYdo=";
            "pubgrub-0.2.1" = "sha256-zusQxYdoNnriUn8JCk5TAW/nQG7fwxksz0GBKEgEHKc=";
            "tl-0.7.8" = "sha256-F06zVeSZA4adT6AzLzz1i9uxpI1b8P1h+05fFfjm3GQ=";
            "version-ranges-0.1.1" = "sha256-zusQxYdoNnriUn8JCk5TAW/nQG7fwxksz0GBKEgEHKc=";
          };
        };
      });
      }
    )
  ];

  home.packages = with pkgs; [
    so
    tokei # code statistics
    cachix
    nix-prefetch-git # nix development
    uv # for python
    jsonnet-bundler
    jsonnet
  ];

}
