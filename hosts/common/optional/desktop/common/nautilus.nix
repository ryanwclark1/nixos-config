{
  pkgs,
  ...
}:

{
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment = {
    sessionVariables = {
      NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";

      # Suppress Tracker and Nautilus warnings in non-GNOME environments
      # These services aren't available/needed in Wayland compositors like Hyprland
      # Disable Tracker indexer (not needed outside full GNOME environment)
      # Note: These warnings are harmless - Nautilus is trying to connect to
      # GNOME services (Tracker, Mutter) that don't exist in non-GNOME environments
      TRACKER_DISABLE_BACKENDS = "all";
    };

    pathsToLink = [
      "/share/nautilus-python/extensions"
    ];

    systemPackages = with pkgs; [
      nautilus
      nautilus-python
      file-roller # Archive manager integration for Nautilus
    ];
  };

  # Enable preview for files in Nautilus
  services.gnome.sushi.enable = true;
}
