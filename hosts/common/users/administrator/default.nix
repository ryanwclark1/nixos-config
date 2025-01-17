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
        "networkmanager"
        "plugdev"
        "podman"
        "postgres"
        "syncthing"
        "wireshark"
      ];

      # openssh.authorizedKeys.keys = [
      #   (builtins.readFile ./keys/id_frametop.pub)
      # ];

      hashedPasswordFile = config.sops.secrets.administrator-password.path;

      packages = [ pkgs.home-manager ];
    };
  };

  nix.settings.trusted-users = [ "${user}" ];

  home-manager.users."${user}" = import ../../../../home/${config.networking.hostName}.nix;

  # security.pam.services = {
  #   swaylock = {};
  # };

    # Persist entire home
  # environment.persistence = {};
}
