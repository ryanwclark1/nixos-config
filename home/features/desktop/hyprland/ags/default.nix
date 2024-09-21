{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.ags.homeManagerModules.default
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
    configDir = ./config;
    extraPackages = with pkgs; [
      accountsservice
    ];
  };
}