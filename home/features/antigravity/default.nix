{ pkgs, ... }:

{
  home.packages = [
    (import ../../../pkgs/antigravity {
      inherit (pkgs)
        lib
        stdenv
        fetchurl
        autoPatchelfHook
        makeWrapper
        ;
      inherit (pkgs)
        alsa-lib
        at-spi2-core
        gtk3
        libdrm
        ;
      inherit (pkgs) xorg;
      inherit (pkgs)
        mesa
        nspr
        nss
        xdg-utils
        ;
    })
  ];
}
