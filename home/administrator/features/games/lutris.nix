{ pkgs, lib, ... }: {
  home.packages = [
    (pkgs.lutris.override { extraPkgs = p: [
      p.wineWowPackages.staging
      p.pixman
      p.libjpeg
      p.gnome.zenity
    ]; })
  ];

  home.persistence = {
    "/persist/home/administrator" = {
      allowOther = true;
      directories = [
        ".config/lutris"
        ".local/share/lutris"
      ];
    };
  };
}
