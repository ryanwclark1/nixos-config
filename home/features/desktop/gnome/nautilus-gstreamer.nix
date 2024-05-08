{
  pkgs,
  lib,
  ...
}:

{
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
  gst-plugins-good
  gst-plugins-bad
  gst-plugins-ugly
  gst-libav
  ]);

  # nixpkgs.overlays = [
  #   (self: super: {
  #     gnome = super.gnome.overrideScope' (gself: gsuper: {
  #       nautilus = gsuper.nautilus.overrideAttrs (nsuper: {
  #         buildInputs = nsuper.buildInputs ++ (with pkgs.gst_all_1; [
  #           gst-plugins-good
  #           gst-plugins-bad
  #         ]);
  #       });
  #     });
  #   })
  # ];
}
