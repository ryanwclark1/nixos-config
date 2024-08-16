# This file (and the global directory) holds config that i use on all hosts
{
  inputs,
  outputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    # ./auto-upgrade.nix
    ./fail2ban.nix
    ./fonts.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./nix-ld.nix
    ./openssh.nix
    # ./optin-persistence.nix
    ./prometheus-node-exporter.nix
    ./sops.nix
    # ./ssh-serve-store.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  # allowUnfree isn't being inherited from the global flake
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = ["/lib/qt-6/plugins"];
  };

  hardware.enableRedistributableFirmware = true;
  networking.domain = "techcasa.io";

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];
}
