{
  pkgs,
  ...
}:

{
  imports = [
    ./deluge.nix
    ./dolphin.nix
    ./discord.nix
    ./firefox.nix
    # ./kdeconnect.nix
    ./slack.nix
    ./sublime-music.nix
  ];

  # home.pointerCursor = {
  #   gtk.enable = true;
  #   package = pkgs.bibata-cursors;
  #   name = "Bibata-Modern-Classic";
  #   size = 16;
  # };

  home.packages = with pkgs; [
    d-spy # Dbus debugger
    ventoy-full #balena type tool
    libnotify
    xdg-utils
    wl-clipboard
    mediainfo
    bluez-tools # bt-adapter
    czkawka # Duplicate file finder
    gpu-viewer
  ];

}
