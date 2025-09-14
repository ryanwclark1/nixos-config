# SOPS secrets management configuration
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # sops-nix options: https://dl.thalheim.io/
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    validateSopsFiles = true;
    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/home/administrator/.ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/keys.txt";
      # generate a new key if none is found
      generateKey = true;
    };
    # System-level secrets that need to be available to system services
    secrets = {
      # WireGuard secrets (will be overridden in individual service configs for specific ownership)
      wg-key = {};
      accent-wg-server = {};
      # Add other system-level secrets here as needed
      administrator-password = {};
    };
  };

  # Add sops-nix package to system packages
  environment.systemPackages = with pkgs; [
    sops
  ];
}
