{ pkgs, ... }:

{
  users.users.ryanc = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # for sudo
    shell = pkgs.zsh;
    # Add other user settings here, for example:
    # home = "/home/ryanc";
    # description = "Ryan C";
  };
}
