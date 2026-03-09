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

    sessionVariables = {
      FLAKE = lib.mkDefault "${config.home.homeDirectory}/nixos-config";
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";
      PAGER = lib.mkDefault "less";
      MANPAGER = lib.mkDefault "sh -c 'col -bx | bat -l man -p'";
      BAT_THEME = lib.mkDefault "theme";
    };


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
