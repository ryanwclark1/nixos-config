{ pkgs, ... }:

{
  home.packages = [
    # pkgs.xorg.libxkbfile
    (import ../../../pkgs/code-cursor {
      inherit (pkgs) lib stdenvNoCC fetchurl appimageTools alsa-lib at-spi2-atk autoPatchelfHook cairo cups curlWithGnuTls egl-wayland expat fontconfig freetype ffmpeg glib glibc glibcLocales gtk3 libappindicator-gtk3 libdrm libgbm libGL libnotify libva-minimal libxkbcommon makeWrapper nspr nss pango pciutils pulseaudio vivaldi-ffmpeg-codecs vulkan-loader wayland rsync undmg;
      inherit (pkgs.xorg) libxkbfile;
    })
  ];
}
# libxkbfile
