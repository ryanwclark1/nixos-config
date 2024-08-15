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
  imports = [ ./packages.nix ];
  users.mutableUsers = false;
  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    shell = "${pkgs.zsh}/bin/zsh";
    extraGroups = [
      "audio"
      "video"
      "wheel"
    ] ++ ifTheyExist [
      "deluge"
      "docker"
      "git"
      "i2c"
      "libvirtd"
      "mysql"
      "network"
      "plugdev"
      "podman"
      "postgres"
      "syncthing"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = [ (builtins.readFile ../../../../home/ssh.pub) ];
    hashedPasswordFile = config.sops.secrets.administrator-password.path;
    packages = [ pkgs.home-manager ];
  };

  sops.secrets.administrator-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.administrator = import ../../../../home/${config.networking.hostName}.nix;

  security.pam.services = {
    swaylock = {};
  };

    # Persist entire home
  environment.persistence = {};
}
