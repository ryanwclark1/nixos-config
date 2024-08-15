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
  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    shell = "${pkgs.zsh}/bin/zsh";
    extraGroups = [
      "wheel"
      "video"
      "audio"
    ] ++ ifTheyExist [
      "network"
      "wireshark"
      "i2c"
      "mysql"
      "docker"
      "podman"
      "git"
      "libvirtd"
      "deluge"
      "syncthing"
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
}
