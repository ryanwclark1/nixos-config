{
  config,
  lib,
  pkgs,
  ...
}:

{
  # nix-index provides the command-not-found functionality and database
  # Note: nix-index replaces the traditional command-not-found program
  programs.nix-index = {
    enable = true;
    package = pkgs.nix-index;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

  # nix-index-database provides pre-built database to avoid initial indexing
  programs.nix-index-database = {
    comma.enable = true;  # Enable comma, which runs programs without installing
  };
  
  # Import the pre-built database weekly updates
  imports = [
    (builtins.fetchurl {
      url = "https://github.com/nix-community/nix-index-database/raw/main/home-manager-module.nix";
      sha256 = "sha256:0p7i1503v09100pfb5wis19rxnmmaqf6kb3z9ixq6p7qz2x3lbfj";
    })
  ];

  # Optional: Manual update script if you want to force updates
  home.packages = [
    (pkgs.writeShellScriptBin "update-nix-index" ''
      echo "Updating nix-index database..."
      filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr '[:upper:]' '[:lower:]')"
      mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
      ${pkgs.wget}/bin/wget -q -N "https://github.com/nix-community/nix-index-database/releases/latest/download/$filename"
      ln -f "$filename" files
      echo "Database updated successfully!"
    '')
  ];
}