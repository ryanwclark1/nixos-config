{
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  # inherit (inputs.nix-colors) colorSchemes;
  # inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) nixWallpaperFromScheme;
  # packageNames = map (p: p.pname or p.name or null) config.home.packages;
  # hasPackage = name: lib.any (x: x == name) packageNames;
  # hasRipgrep = hasPackage "ripgrep";
  hasNeovim = config.programs.neovim.enable;
  hasKitty = config.programs.kitty.enable;
  # hasZoxide = config.programs.zoxide.enable;
in
{
  imports = [
    inputs.nix-colors.homeManagerModule
    # ./global-fonts.nix
    ./style.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };


  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "administrator";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault config.system.nixos.release;
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      FLAKE = lib.mkDefault "$HOME/nixos-config";
      EDITOR = lib.mkDefault "${pkgs.neovim}/bin/nvim";
      # SHELL = lib.mkDefault "${pkgs.bash}/bin/bash";
      # TERM = "${pkgs.alacritty}/bin/alacritty";
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

      cik = mkIf hasKitty "clone-in-kitty --type os-window";
      ck = cik;
    };
  };

  # home.file = {
  #   ".colorscheme".text = config.colorscheme.slug;
  #   ".colorscheme.json".text = builtins.toJSON config.colorscheme;
  # };

  home.packages =
    let
      specialisation = pkgs.writeShellScriptBin "specialisation" ''
        profiles="$HOME/.local/state/nix/profiles"
        current="$profiles/home-manager"
        base="$profiles/home-manager-base"

        # If current contains specialisations, link it as base
        if [ -d "$current/specialisation" ]; then
          echo >&2 "Using current profile as base"
          ln -sfT "$(readlink "$current")" "$base"
        # Check that $base contains specialisations before proceeding
        elif [ -d "$base/specialisation" ]; then
          echo >&2 "Using previously linked base profile"
        else
          echo >&2 "No suitable base config found. Try 'home-manager switch' again."
          exit 1
        fi

        if [ "$1" = "list" ] || [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
          find "$base/specialisation" -type l -printf "%f\n"
          exit 0
        fi

        echo >&2 "Switching to ''${1:-base} specialisation"
        if [ -n "$1" ]; then
          "$base/specialisation/$1/activate"
        else
          "$base/activate"
        fi
      '';
      toggle-theme = pkgs.writeShellScriptBin "toggle-theme" ''
        if [ -n "$1" ]; then
          theme="$1"
        else
          current="$(${lib.getExe pkgs.jq} -re '.variant' "$HOME/.colorscheme.json")"
          if [ "$current" = "light" ]; then
            theme="dark"
          else
            theme="light"
          fi
        fi
        ${lib.getExe specialisation} "$theme"
      '';
    in
    [ specialisation toggle-theme ];
}
