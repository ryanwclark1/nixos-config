{
  config,
  lib,
  pkgs,
  outputs,
  ...
}:

{
  # Nix configuration handled by system-level config in hosts/common/global/nix.nix

  # systemd.user.startServices = "sd-switch";
  systemd.user.startServices = "suggest";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "administrator";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "24.11";
    # sessionPath moved to shell/common.nix
    sessionVariables = {
      FLAKE = lib.mkDefault "${config.home.homeDirectory}/nixos-config";
      # EDITOR, VISUAL, and MANPAGER moved to shell/common.nix
    };
    # shellAliases moved to shell/common.nix


    # persistence = {};
    # persistence = {
    #   "/persist${config.home.homeDirectory}" = {
    #     defaultDirectoryMethod = "symlink";
    #     directories = [
    #       "documents"
    #       "downloads"
    #       "pictures"
    #       "videos"
    #       ".local/bin"
    #       ".local/share/nix" # trusted settings and repl history
    #     ];
    #     allowOther = true;
    #   };
    # };
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
}
