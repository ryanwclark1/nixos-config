{ lib, pkgs, ... }: {
  home = {
    packages = [ pkgs.heroic ];
    # persistence = {
    #   "/persist/home/administrator" = {
    #     allowOther = true;
    #     directories = [ ".heroic" ];
    #   };
    # };
  };
}
