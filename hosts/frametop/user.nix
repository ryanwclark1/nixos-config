# ./host/frametop/user.nix
{
  users.users.administrator = {
  isNormalUser = true;
  description = "administrator";
  extraGroups = [ "audio" "docker" "networkmanager" "video" "wheel" ];
  openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJx3Sk20pLL1b2PPKZey2oTyioODrErq83xG78YpFBoj admin@xxxx"
  ];
  };
}