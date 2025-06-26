{
  pkgs,
  ...
}:

{
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };

  environment = {
    sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    pathsToLink = [
      "/share/nautilus-python/extensions"
    ];

    systemPackages = with pkgs; [
      nautilus
      nautilus-python
    ];
  };

  # Enable preview for files in Nautilus
  services.gnome.sushi.enable = true;
}