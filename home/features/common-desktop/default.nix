{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {

  home.packages = with pkgs; [

    openssl_3
    dfeet # Dbus debugger
    d2 #diagram
    zk # note taking
    trashy #cli rm with trash support
    ventoy-full #balena type tool
    hurl # httpie/curl alternative
    # utils
    acpica-tools

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool

    # misc
    libnotify
    wineWowPackages.wayland
    # wineWowPackages.stagingFull
    xdg-utils
    graphviz
    # Wayland, Xorg
    wl-clipboard
    mediainfo
    remmina         # XRDP & VNC Client
    bluez-tools # bt-adapter
    usbutils # lsusb
    kate
    # neovim
    scrot
    discord
    element-desktop
    megatools
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