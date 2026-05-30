{
  ...
}:
let
  user = "ryanclark";
  hostName = "neo";
in
{
  imports = [
    ../common/darwin
  ];

  home-manager.users."${user}" = import ../../home/${hostName}.nix;

  users.users."${user}" = {
    name = "${user}";
    home = "/Users/${user}";
  };

  system.primaryUser = user;
}
