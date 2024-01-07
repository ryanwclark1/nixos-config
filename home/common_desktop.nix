{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.common_desktop.enable = mkEnableOption "common desktop settings";

  config = mkIf config.common_desktop.enable {

    home.packages = with pkgs; [
      neofetch

      mprocs # multiple commands in parallel

      gum # shell scripts

      hyperfine #cli benchmarking tool

      pkg-config
      openssl_3

      dfeet # Dbus debugger

      d2 #diagram
      zk # note taking
      trashy #cli rm with trash support

      ventoy-full #balena type tool

      hurl # httpie/curl alternative

      # utils
      yq-go    # https://github.com/mikefarah/yq
      # nfs-utils
      iw
      nmap
      netcat
      tree
      mc
      acpica-tools


      # system tools
      sysstat
      lm_sensors # for `sensors` command
      ethtool
      pciutils # lspci
      usbutils # lsusb

      # misc
      libnotify
      wineWowPackages.wayland
      # wineWowPackages.stagingFull
      xdg-utils
      graphviz

      # productivity
      # obsidian

      # cloud native
      kubectl
      kubernetes-helm
      minikube

      # Need libpq but can't find
      postgresql

      # Wayland, Xorg
      wl-clipboard

      mediainfo
      remmina         # XRDP & VNC Client

      bluez-tools # bt-adapter
      usbutils # lsusb

      kate
      neovim
      scrot
      discord
      element-desktop
      megatools

      transmission
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
  };
}