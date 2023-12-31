 # users/administrator/home.nix
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./programs
    ./shell
    # ./users/administrator
  ];

  home = {
    username = "administrator";
    homeDirectory = "/home/administrator";
    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;
}
