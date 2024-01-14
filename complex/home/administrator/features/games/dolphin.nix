{ lib, pkgs, ... }: {
  home = {
    packages = [ pkgs.dolphinEmu ];
    # persistence = {
    #   "/persist/home/administrator" = {
    #     allowOther = true;
    #     directories = [ ".dolphin" ];
    #   };
    # };
  };
}