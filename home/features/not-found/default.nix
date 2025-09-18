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
  
  # Install comma for running programs without installing
  home.packages = with pkgs; [
    comma  # Run programs without installing: , hello
    (writeShellScriptBin "update-nix-index" ''
      echo "Updating nix-index database..."
      filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr '[:upper:]' '[:lower:]')"
      mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
      ${wget}/bin/wget -q -N "https://github.com/nix-community/nix-index-database/releases/latest/download/$filename"
      ln -f "$filename" files
      echo "Database updated successfully!"
    '')
  ];

  # Automatic database updates via systemd timer
  systemd.user.services.nix-index-database-sync = {
    Unit = { 
      Description = "Fetch nix-index database"; 
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.profileDirectory}/bin/update-nix-index";
      Restart = "on-failure";
      RestartSec = "5m";
    };
  };

  systemd.user.timers.nix-index-database-sync = {
    Unit = { 
      Description = "Automatic nix-index database fetching"; 
    };
    Timer = {
      OnBootSec = "10m";
      OnUnitActiveSec = "24h";  # Update daily
    };
    Install = { 
      WantedBy = [ "timers.target" ]; 
    };
  };
}