{
  config,
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
  };

  # Ensure sops-nix is available in the system
  environment.systemPackages = with pkgs; [
    inputs.sops-nix.packages.${pkgs.system}.sops
  ];
}
