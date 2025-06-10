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
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
    sessionVariables = {
      FLAKE = lib.mkDefault "${config.home.homeDirectory}/nixos-config";
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";
      MANPAGER = lib.mkDefault "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT="-c";
    };
    shellAliases = rec {
      jqless = "jq -C | bat --pager 'less RF' --style=numbers --color=always";

      wifi = "nmtui";

      cik = lib.mkIf config.programs.kitty.enable "clone-in-kitty --type os-window";
      ck = cik;
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

  # home.file = {
  #   ".colorscheme".text = config.colorscheme.slug;
  #   ".colorscheme.json".text = builtins.toJSON config.colorscheme;
  # };

}
