{
  config,
  lib,
  pkgs,
  ...
}:
let
  update-script = pkgs.writeShellApplication {
    name = "fetch-nix-index-database";
    runtimeInputs = with pkgs; [ wget coreutils ];
    text = ''
      filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr '[:upper:]' '[:lower:]')"
      mkdir -p ~/.local/cache/nix-index && cd ~/.local/cache/nix-index
      wget -q -N "https://github.com/nix-community/nix-index-database/releases/latest/download/$filename"
      ln -f "$filename" files
    '';
  };
in
{
  home.packages = with pkgs; [
    alejandra
    comma
    deadnix
    nil # Nix LSP
    niv
    nix-diff
    nvd
    nix-tree # Interactively browse dependency graphs of Nix derivations
    nix-update
    nixpkgs-lint
    nurl # Generate Nix fetcher calls from repository URLs
    patchelf
    # sops
  ];

  programs.nix-index = {
    enable = true;
    package = pkgs.nix-index;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

  systemd.user.services.nix-index-database-sync = {
    Unit = { Description = "fetch mic92/nix-index-database"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${update-script}/bin/fetch-nix-index-database";
      Restart = "on-failure";
      RestartSec = "5m";
    };
  };
  systemd.user.timers.nix-index-database-sync = {
    Unit = { Description = "Automatic github:mic92/nix-index-database fetching"; };
    Timer = {
      OnBootSec = "10m";
      OnUnitActiveSec = "24h";
    };
    Install = { WantedBy = [ "timers.target" ]; };
  };
}
