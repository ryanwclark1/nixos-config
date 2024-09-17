{
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  # sops-nix options: https://dl.thalheim.io/
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    validateSopsFiles = true;
    # generate a new key if none is found
    generateKey = true;
    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/home/administrator/.ssh/ssh_host_ed25519_key"
      ];
      keyFile = "$HOME/.config/sops/age/keys.txt";
    };
    secrets = {
      administrator-password = {};
      "private_keys/administrator" = {};
    };
  };
}