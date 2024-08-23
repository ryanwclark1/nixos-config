{
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
    # ./global-fonts.nix
    ./style.nix
    ./sops.nix
  ]
  ++ (builtins.attrValues outputs.homeManagerModules);

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  # nixpkgs = {
  #   overlays = builtins.attrValues outputs.overlays;
  #   config = {
  #     allowUnfree = true;
  #     allowUnfreePredicate = (_: true);
  #   };
  # };

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home =
  let
    editor = lib.getExe config.programs.nixvim.package;
    terminal = lib.getExe config.alacritty.nixvim.package;
  in
  {
    username = lib.mkDefault "administrator";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "24.11";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      FLAKE = lib.mkDefault "$HOME/nixos-config";
      EDITOR = lib.mkDefault "${editor}";
      TERM = "${terminal}";
    };
    shellAliases = rec{
      jqless = "jq -C | less -r";

      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";

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

  # home.file = {
  #   ".colorscheme".text = config.colorscheme.slug;
  #   ".colorscheme.json".text = builtins.toJSON config.colorscheme;
  # };

}
