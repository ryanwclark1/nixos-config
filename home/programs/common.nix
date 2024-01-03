{
  pkgs,
  config,
  ...
}:

{
  home.packages = with pkgs; [

    neofetch
    # utils
    yq-go    # https://github.com/mikefarah/yq
    nfs-utils
    iw
    nmap
    netcat
    tree
    mc
    acpica-tools

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    wireguard-tools

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb

    # misc
    libnotify
    wineWowPackages.wayland
    xdg-utils
    graphviz

    # Nix
    nix-init
    nix-tree
    nix-update

    # productivity
    obsidian

    # cloud native
    kubectl
    kubernetes-helm
    minikube

    nodejs
    nodePackages.npm
    nodePackages.pnpm
    yarn

    poetry
    python311
    python311Packages.poetry-core
    python311Packages.pdm-backend
    python311Packages.pipx
    python311Packages.pip

    libgcc
    gcc

    # Need libpq but can't find
    postgresql

    # db related
    dbeaver
    mycli
    pgcli

    # Wayland, Xorg
    wl-clipboard

    # Filesystem stuff
    gparted
    dosfstools
    mtools
    ntfs3g
    btrfs-progs
    jmtpfs
    jdupes

    mediainfo
    gnumake
    remmina         # XRDP & VNC Client

    bluez-tools # bt-adapter
    usbutils # lsusb

    # Monitoring
    lm_sensors # sensors
    smartmontools # smartctl
    psensor # GUI for lm_sensors

    kate
    vlc
    handbrake
    blender
    neovim
    scrot
    # nnn # Remove nnn from common
    # discord
    # element-desktop
    megatools

    transmission
    f1viewer
    tickrs

    # Nix tooling
    alejandra
    deadnix
    statix
  ];

  programs = {
    tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      extraConfig = "mouse on";
    };

    btop.enable = true;  # replacement of htop/nmon

    # aria2.enable = true;
  };


  # programs.bash = {
  #   enable = true;
  #   enableCompletion = true;
  #   # TODO add your cusotm bashrc here
  #   bashrcExtra = ''
  #     neofetch
  #     export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
  #   '';

  #   # set some aliases
  #   # shellAliases = {
  #   #   k = "kubectl";
  #   #   urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
  #   #   urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

  #   #   #  Use `lib.mkForce value` or `lib.mkDefault value` to change the priority on any of these definitions.
  #   #   # ls = "eza -lag --icons --header --group-directories-first";
  #   #   # lr = "eza -lTg --icons --header --group-directories-first";

  #   # };
  # };

  services = {
    syncthing.enable = true;
    # auto mount usb drives
    udiskie.enable = true;
  };
}
