{ lib, pkgs, ... }: {
  home = {
    packages = [ pkgs.factorio ];
    persistence = {
      "/persist/home/administrator" = {
        allowOther = true;
        directories = [ ".factorio" ];
      };
    };
  };
}
