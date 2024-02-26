{
  config,
  pkgs,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [ ./packages.nix ];
  # users.mutableUsers = false;
  users.users.administrator = {
    isNormalUser = true;
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

  # services.geoclue2.enable = true;
  # security.pam.services = { swaylock = { }; };
}
