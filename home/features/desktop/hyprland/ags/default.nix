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
    # inputs.astal.nixosModules.default
  ];

  home.packages = with pkgs; [
    bun
    dart-sass
  ];

  programs.ags = {
    enable = true;
 
      # ags.packages.x86_64-linux.battery
      # ags.packages.x86_64-linux.hyperland
    # ];
    # extraPackages = with pkgs; [
    #   gtksourceview
    #   webkitgtk_6_0
    #   accountsservice
    # ];
  };
  programs.matugen = {
    enable = true;
    variant = "dark";
    jsonFormat = "hex";
  };

}