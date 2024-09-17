{
  pkgs,
  ...
}:
let
  update-script = pkgs.writeShellApplication {
    name = "fetch-nix-index-database";
    runtimeInputs = with pkgs; [ wget coreutils ];
    text = ''
      filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr '[:upper:]' '[:lower:]')"
      mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
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
    nh # Nice wrapper for NixOS and HM
    nil # Nix LSP
    niv
    nix-diff
    nix-tree # Interactively browse dependency graphs of Nix derivations
    nix-update
    nixpkgs-lint
    nurl # Generate Nix fetcher calls from repository URLs
    nvd # Differ
    patchelf
    sops
  ];

  programs.nix-index = {
    enable = true;
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
