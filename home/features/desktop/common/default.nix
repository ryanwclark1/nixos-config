{
  pkgs,
  ...
}:

{
  imports = [
    ./deluge.nix
    ./discord.nix
    ./dragon.nix
    ./firefox.nix
    ./font.nix
    ./kdeconnect.nix
    ./pavucontrol.nix
    ./playerctl.nix
    ./slack.nix
    ./sublime-music.nix
  ];


  nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "freeimage-unstable-2021-11-01"
  ];

  home.packages = with pkgs; [
    fortune
    dfeet # Dbus debugger
    ventoy-full #balena type tool
    etcher
    libnotify
    wineWowPackages.wayland
    xdg-utils
    wl-clipboard
    mediainfo
    remmina # XRDP & VNC Client
    bluez-tools # bt-adapter
    scrot
    element-desktop
    megatools
    megasync
    czkawka # Duplicate file finder
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
