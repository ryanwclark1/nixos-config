{
  description = "Ryan's NixOS Flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aspen = {
      url = "github:prmadev/aspen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    hyprland.url = "github:hyprwm/Hyprland";
    # plasma-manager = {
    #   url = "github:pjones/plasma-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.home-manager.follows = "home-manager";
    # };
  };

  outputs = {
    self,
    nixpkgs,
    vscode-server,
    ...
  } @ inputs:
    let
      # Flakes are evaluated hermetically, thus are unable to access
      # host environment (including looking up current system).
      #
      # That's why flakes must explicitly export sets for each system
      # supported.
      system = "x86_64-linux";
      # pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs) lib;
    in
      with inputs;
    {
      nixosConfigurations = {

        woody = lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/woody/configuration.nix
            inputs.home-manager.nixosModules.default
            inputs.vscode-server.nixosModules.default
            # inputs.plasma-manager.homeManagerModules.plasma-manager
          ];
        };

        frametop = lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/frametop/configuration.nix
            nixos-hardware.nixosModules.framework-12th-gen-intel
            inputs.home-manager.nixosModules.default
            inputs.vscode-server.nixosModules.default
            # inputs.plasma-manager.homeManagerModules.plasma-manager
          ];
        };

      };
    };
}
