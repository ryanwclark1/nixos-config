{ pkgs, lib, ... }: {
  home.packages = [ pkgs.osu-lazer ];

  home.persistence = {
    "/persist/home/administrator".directories = [ ".local/share/osu" ];
  };
}
