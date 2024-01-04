# flake.nix
{
  description = "Ryan's NixOS Flake";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
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
    zsh-windows-title = {
      url = "github:mdarocha/zsh-windows-title";
      flake = false;
    };
    zsh-terminal-title = {
      url = "github:AnimiVulpis/zsh-terminal-title";
      flake = false;
    };
    zsh-skim = {
      url = "github:casonadams/skim.zsh";
      flake = false;
    };
    catppuccin-zsh = {
      url = "github:catppuccin/zsh-syntax-highlighting";
      flake = false;
    };
    zsh-tab-title = {
      url = "github:trystan2k/zsh-tab-title";
      flake = false;
    };
    zsh-nix-shell = {
      url = "github:chisui/zsh-nix-shell";
      flake = false;
    };
    zsh-nix-completion = {
      url = "github:nix-community/nix-zsh-completions";
      flake = false;
    };
    cd-ls = {
      url = "github:zshzoo/cd-ls";
      flake = false;
    };
    colorize = {
      url = "github:zpm-zsh/colorize";
      flake = false;
    };
    bat-catppuccin = {
      url = "github:catppuccin/bat";

      flake = false;
    };
    snippets-ls = {
      url = "git+https://git.sr.ht/~prma/snippets-ls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix = {
      url = "github:helix-editor/helix";
      # inputs.nixpkgs.follows = "nixpkgs";
      # helix.inputs.nixpkgs.follows = "nixpkgs";
      # in
    };
    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aspen = {
      url = "github:prmadev/aspen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    himalaya = {
      url = "github:soywod/himalaya";
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
          {
            nixpkgs.overlays = [
              # inputs.nixneovim.overlays.default
              inputs.nur.overlay
              # inputs.neovim-nightly-overlay.overlay
              (final: prev: {external.snippets-ls = snippets-ls.packages.${prev.system}.snippets-ls;})
            ];
          }
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
            home-manager.users.administrator = {
              home.stateVersion = "23.11";
              imports = [
                ./home
                nixvim.homeManagerModules.nixvim
                ];
            };
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
            home-manager.users.administrator = {
              home.stateVersion = "23.11";
              imports = [
                ./home
                nixvim.homeManagerModules.nixvim
                ];
            };
          }
        ];
      };
      # ... other configurations like nucdesktop ...
    };

    # ... other potential outputs ...
  };
}

