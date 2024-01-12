{ pkgs, lib, ... }: {
  home.packages = [ pkgs.sublime-music ];
  home.persistence = {
    "/persist/home/administrator".directories = [ ".config/sublime-music" ];
  };
}
