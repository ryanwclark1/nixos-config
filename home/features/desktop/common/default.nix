{
  pkgs,
  ...
}:

{
  imports = [
    ./deluge.nix
    ./discord.nix
    ./firefox.nix
    ./kdeconnect.nix
    ./slack.nix
    ./sublime-music.nix
  ];

  home.packages = with pkgs; [
    d-spy # Dbus debugger
    ventoy-full #balena type tool
    libnotify
    xdg-utils
    wl-clipboard
    mediainfo
    bluez-tools # bt-adapter
    element-desktop
    megasync
    czkawka # Duplicate file finder
    gpu-viewer
  ];

}
