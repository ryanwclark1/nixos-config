{
  pkgs,
  ...
}:

{
  imports = [
    ./deluge.nix
    ./discord.nix
    #   ./dragon.nix
    ./firefox.nix
    ./font.nix
    #   ./gtk.nix
    ./kdeconnect.nix
    #   ./pavucontrol.nix
    #   ./playerctl.nix
    #   ./qt.nix
    #   ./slack.nix
    #   ./sublime-music.nix
  ];

  # Requires an implementation in xdg.portal.extraportals such as xdg-desktop-portal-kde or xdg-desktop-portal-gtk
  # xdg.portal.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
  ];

  home.packages = with pkgs; [
    fortune
    # openssl_3
    dfeet # Dbus debugger

    ventoy-full #balena type tool
    etcher

    # misc
    libnotify
    wineWowPackages.wayland
    # wineWowPackages.stagingFull
    xdg-utils
    # Wayland, Xorg
    wl-clipboard
    mediainfo
    remmina # XRDP & VNC Client
    bluez-tools # bt-adapter

    kate

    scrot
    element-desktop
    megatools
    megasync
    # Duplicate file finder
    czkawka
    f1viewer
    tickrs
    # fantomas

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

}
