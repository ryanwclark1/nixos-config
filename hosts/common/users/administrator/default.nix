{
  config,
  pkgs,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  user = "administrator";
in
{
  # imports = [ ./packages.nix ];

  sops.secrets.administrator-password = {
    sopsFile = ../../../../secrets/secrets.yaml;
    # Decrypt password to /run/secrets-fo-users/ so it can be used to create the user
    neededForUsers = true;
  };
  # switch back to mutableusers = false
  users.mutableUsers = true;
  users = {
    users."${user}" = {
      name = "${user}";
      isNormalUser = true;
      home = "/home/${user}";
      shell = "${pkgs.zsh}/bin/zsh";
      extraGroups =
        [
          "audio"
          "video"
          "wheel"
          "input"
          "kvm"
          "render"
          "scanner"
          "lp"
          "cdrom"
          "floppy"
          "tape"
          "dialout"
          "tty"
          "disk"
          "kmem"
          "sys"
          "adm"
        ]
        ++ ifTheyExist [
          "deluge"
          "docker"
          "git"
          "i2c"
          "libvirtd"
          "mysql"
          "network"
          "networkmanager"
          "plugdev"
          "podman"
          "postgres"
          "syncthing"
          "wireshark"
        ];

      # SSH authorized keys for secure remote access
      openssh.authorizedKeys.keys = [
        # Frametop host key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+GFRs3psesCwnY5kLAmtRKRbUXrTUcOUNsdaCTuLyW"
      ];

      hashedPasswordFile = config.sops.secrets.administrator-password.path;

      # Account security settings
      createHome = true;
      homeMode = "0755";
      uid = 1000;
      group = "users";

      # Allow password changes
      hashedPassword = null;

      packages = [
        pkgs.home-manager
        pkgs.btop
        pkgs.iotop
        pkgs.nvme-cli
        pkgs.smartmontools
        pkgs.lsof
        pkgs.strace
        pkgs.tcpdump
        pkgs.wireshark
        pkgs.nmap
        pkgs.openssl
        pkgs.gnupg
        pkgs.pass
        pkgs.git
        pkgs.curl
        pkgs.wget
        pkgs.jq
        pkgs.bat
        pkgs.fd
        pkgs.ripgrep
        pkgs.fzf
        pkgs.tmux
        pkgs.zsh
        pkgs.neovim
        pkgs.util-linux
      ];
    };
  };

  nix.settings.trusted-users = [ "${user}" ];

  # Administrator-specific environment variables
  environment.variables = {
    ADMIN_USER = "${user}";
    ADMIN_HOME = "/home/${user}";
    NIXOS_CONFIG = "/home/${user}/nixos-config";
  };

  # Administrator-specific session variables
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "/home/${user}/.config";
    XDG_CACHE_HOME = "/home/${user}/.cache";
    XDG_DATA_HOME = "/home/${user}/.local/share";
    XDG_STATE_HOME = "/home/${user}/.local/state";
  };

  home-manager.users."${user}" = import ../../../../home/${config.networking.hostName}.nix;

  # Persist entire home directory for administrator
  # environment.persistence = {
  #   "/persist" = {
  #     directories = [
  #       "/home/${user}"
  #     ];
  #     users.${user} = {
  #       directories = [
  #         "documents"
  #         "downloads"
  #         "pictures"
  #         "videos"
  #         "music"
  #         ".local/bin"
  #         ".local/share/nix"
  #         ".ssh"
  #         ".gnupg"
  #         ".config"
  #         ".cache"
  #       ];
  #     };
  #   };
  # };
}
