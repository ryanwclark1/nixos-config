{
  description = "Ryan's NixOS Flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-colors.url = "github:misterio77/nix-colors";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aspen = {
      url = "github:prmadev/aspen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = {
    self,
    nixpkgs,
    vscode-server,
    home-manager,
    ...
  } @ inputs:
    let
      inherit (self) outputs;
      # Flakes must explicitly export sets for each system supported.
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # inherit (nixpkgs) lib;
    in
      with inputs;
    {
      nixosConfigurations = {

        woody = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/woody/configuration.nix
            inputs.home-manager.nixosModules.default
          ];
        };

        frametop = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/frametop/configuration.nix
            nixos-hardware.nixosModules.framework-12th-gen-intel
            inputs.home-manager.nixosModules.default
          ];
        };

      };
    };
}
