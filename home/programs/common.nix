{
  inputs,
  system,
  pkgs,
  config,
  ...
}:

{
  home.packages = with pkgs; [

    freshfetch
    neofetch

    # archives
    zip
    xz
    unzip
    p7zip
    zstd
    zpaq
    unrar

    # utils
    ripgrep
    yq-go    # https://github.com/mikefarah/yq
    fzf
    duf
    nfs-utils
    iw
    nmap
    netcat
    tree
    mc
    imagemagick
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

    # IDE
    insomnia

    # cloud native
    docker
    kubectl
    kubernetes-helm
    minikube

    nodejs
    nodePackages.npm
    nodePackages.pnpm
    yarn

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
    lm_sensors # sensors
    smartmontools # smartctl

    kate
    vlc
    # neovim
    # curl
    scrot
    nnn # Remove nnn from common
    firefox
    # discord
    # element-desktop
    megatools

    transmission
  ];

  programs = {
    tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      extraConfig = "mouse on";
    };

    btop.enable = true;  # replacement of htop/nmon
    # exa.enable = true;   # A modern replacement for ‘ls’
    jq.enable = true;    # A lightweight and flexible command-line JSON processor
    ssh.enable = true;
    aria2.enable = true;

    skim = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden";
      changeDirWidgetOptions = [
        "--preview 'exa --icons --git --color always -T -L 3 {} | head -200'"
        "--exact"
      ];
    };
  };


  programs.bash = {
    enable = true;
    enableCompletion = true;
    # TODO add your cusotm bashrc here
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';

    # set some aliases, feel free to add more or remove some
    shellAliases = {
      k = "kubectl";
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
    };
  };

  services = {
    syncthing.enable = true;

    # auto mount usb drives
    udiskie.enable = true;
  };
}
