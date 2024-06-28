{
  pkgs,
  ...
}:

{
  imports = [
    ./deluge.nix
    ./discord.nix
    ./firefox.nix
    # ./kdeconnect.nix
    ./slack.nix
    # ./sublime-music.nix
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
    megatools
    megasync
    czkawka # Duplicate file finder
    f1viewer
    tickrs
    gpu-viewer

    # fantomas
    # multiviewer

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
