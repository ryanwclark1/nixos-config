{
  config,
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
    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "${config.home.homeDirectory}/.ssh/ssh_host_ed25519_key"
      ];
      keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      # generate a new key if none is found
      generateKey = true;
    };
    secrets = {
      administrator-password = {};
      "private_keys/administrator" = {};
    };
  };
}