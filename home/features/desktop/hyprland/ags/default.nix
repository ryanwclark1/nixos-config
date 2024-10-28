{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.ags.homeManagerModules.default
    inputs.matugen.nixosModules.default
  ];

  home.packages = with pkgs; [
    bun
    dart-sass
  ];

    # home.file.".config/ags/" = {
    #     source = ./config;
    #     recursive = true;
    # };

  programs.ags = {
    enable = true;
    # configDir = ./backup;
    extraPackages = with pkgs; [
      gtksourceview
      webkitgtk_6_0
      accountsservice
    ];
  };
  programs.matugen = {
    enable = true;
    variant = "dark";
    jsonFormat = "hex";
  };

}