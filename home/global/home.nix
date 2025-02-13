{
  config,
  lib,
  pkgs,
  ...
}:

{
  # duplicated in host/common/global/nix.nix
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

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

      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild switch --flake .";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild switch --flake .";
      hm = "home-manager --flake .";
      hms = "home-manager switch --flake .";

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

  # nixpkgs = {
  #   overlays = builtins.attrValues outputs.overlays;
  #   config = {
  #     allowUnfree = true;
  #     allowUnfreePredicate = _: true;
  #   };
  # };

  # home.file = {
  #   ".colorscheme".text = config.colorscheme.slug;
  #   ".colorscheme.json".text = builtins.toJSON config.colorscheme;
  # };

}
