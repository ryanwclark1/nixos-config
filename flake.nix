{
  description = "Nixos config flake";

  inputs = {
    #################### Official NixOS and HM Package Sources ####################
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    #################### Utilities ####################

    systems.url = "github:nix-systems/default-linux";
    impermanence.url = "github:nix-community/impermanence";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      # Check this periodically
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixvim = {
    #   url = "github:ryanwclark1/nixvim";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    ags.url = "github:Aylur/ags";
    matugen = {
      url = "github:/InioX/Matugen";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    disko,
    lanzaboote,
    nixos-cosmic,
    nixvim,
    stylix,
    systems,
    ...
  } @ inputs:
  let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    # systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs (import systems) (
    system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }
    );
  in
  {
    inherit lib;
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;
    # templates = import ./templates;

    packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
    devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
    formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
    overlays = import ./overlays { inherit inputs outputs; };

    nixosConfigurations = {
      frametop = lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          stylix.nixosModules.stylix
          disko.nixosModules.disko
          nixos-cosmic.nixosModules.default
          ./hosts/frametop
        ];
      };
      woody = lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          stylix.nixosModules.stylix
          nixos-cosmic.nixosModules.default
          ./hosts/woody
        ];
      };

    };
    homeConfigurations = {
      "administrator@frametop" = lib.homeManagerConfiguration {
        modules = [
          stylix.homeManagerModules.stylix
          ./home/frametop.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
      "administrator@woody" = lib.homeManagerConfiguration {
        modules = [
          stylix.homeManagerModules.stylix
          ./home/woody.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
       "administrator@accent" = lib.homeManagerConfiguration {
        modules = [
          stylix.homeManagerModules.stylix
          ./home/accent.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
      "root@vlad" = lib.homeManagerConfiguration {
        modules = [
          stylix.homeManagerModules.stylix
          ./home/vlad.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
    };
  };
}
