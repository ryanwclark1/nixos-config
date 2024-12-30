{
  config,
  pkgs,
  ...
}:

{
  imports = [
    # ./dolphinemu.nix
    # ./factorio.nix
    # ./heroic.nix
    # ./lutris.nix
    # ./steam.nix
    # ./gamescope.nix
    # ./zeroad.nix
    # ./openra.nix
    # ./xonotic.nix
  ];


    # persistence = {
    #   "/persist/${config.home.homeDirectory}" = {
    #     allowOther = true;
    #     directories = [
    #       "games"
    #     ];
    #   };
    # };
}
