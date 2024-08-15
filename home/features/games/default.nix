{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./dolphin.nix
    # ./factorio.nix
    ./heroic.nix
    ./lutris.nix
    # ./steam.nix
    # ./gamescope.nix
    # ./zeroad.nix
    # ./openra.nix
    # ./xonotic.nix
  ];
  home = {
    packages = with pkgs; [gamescope];
    persistence = {
      "/persist/${config.home.homeDirectory}" = {
        allowOther = true;
        directories = [
          "games"
        ];
      };
    };
  };
}
