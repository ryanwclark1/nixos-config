# flake.nix
{
  description = "Ryan's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/release-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nnn-plugins = {
      url = "github:jarun/nnn";
      flake = false;
    };
    fzf-tab = {
      url = "github:Aloxaf/fzf-tab";
      flake = false;
    };
    fzf-finder = {
      url = "github:leophys/zsh-plugin-fzf-finder";
      flake = false;
    };
    catppuccin-fish = {
      url = "github:catppuccin/fish";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    ...
    } @ inputs: let
      system = "x86_64-linux";
      inherit (nixpkgs) lib;
    in
      with inputs; {

    nixosConfigurations = {
      frametop = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/frametop
          nixos-hardware.nixosModules.framework-12th-gen-intel
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit system;
            };
            home-manager.users.administrator = import ./home;
          }
        ];
      };
      woody = lib.nixosSystem {
        inherit system;
        modules = [
          {
            nixpkgs.overlays = [
              # inputs.nixneovim.overlays.default
              inputs.nur.overlay
              # inputs.neovim-nightly-overlay.overlay
              (final: prev: {external.snippets-ls = snippets-ls.packages.${prev.system}.snippets-ls;})
            ];
          }
          ./hosts/woody
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit system;
            };
            home-manager.users.administrator = import ./home;
          }
        ];
      };
      # ... other configurations like nucdesktop ...
    };

    # ... other potential outputs ...
  };
}

