{ inputs, nixosConfig, pkgs, lib, ... }:
let
  spicetify-nix = inputs.spicetify-nix;
  spicePkgs = spicetify-nix.packages.${pkgs.system}.default;
in
# NOTE: lib.mkIf nixosConfig.setup.gui.enable { Error! Why? I don't know.
# Simon : Because imports can't be conditional
{

  # allow spotify to be installed if you don't have unfree enabled already
  nixpkgs.config.allowUnfreePredicate = lib.mkIf lib.mkIf nixosConfig.setup.gui.desktop.enable (pkg: builtins.elem (lib.getName pkg) [
    "spotify"
  ]);

  # import the flake's module for your system
  imports = [ spicetify-nix.homeManagerModule ];

  # configure spicetify :)
  programs.spicetify = lib.mkIf nixosConfig.setup.gui.desktop.enable {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "macchiato";
    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      shuffle # shuffle+ (special characters are sanitized out of ext names)
      hidePodcasts
      playlistIcons
      genre
      lastfm
      historyShortcut
    ];
  };

}
