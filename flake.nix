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
<<<<<<< HEAD
    # hyprland.url = "github:hyprwm/Hyprland";
    # plasma-manager = {
      #   url = "github:pjones/plasma-manager";
      #   inputs.nixpkgs.follows = "nixpkgs";
      #   inputs.home-manager.follows = "home-manager";
    # };
=======
    hyprland.url = "github:hyprwm/Hyprland";
>>>>>>> b4ad8ab151e75a74704a46be1244d06e2a0dbcf9
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
            inputs.vscode-server.nixosModules.default
          ];
        };

        frametop = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            ./hosts/frametop/configuration.nix
            nixos-hardware.nixosModules.framework-12th-gen-intel
            inputs.home-manager.nixosModules.default
            inputs.vscode-server.nixosModules.default
<<<<<<< HEAD
            # inputs.hyprland.nixosModules.default
            # inputs.plasma-manager.homeManagerModules.plasma-manager
=======
            inputs.hyprland.nixosModules.default
>>>>>>> b4ad8ab151e75a74704a46be1244d06e2a0dbcf9
          ];
        };

      };
    };
}
