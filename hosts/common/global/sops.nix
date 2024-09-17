# Host level sops configuration
{
  config,
  inputs,
  ...
}:
let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  secretsFile = "${secretsDirectory}/secrets.yaml";
  isEd25519 = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # sops-nix options: https://dl.thalheim.io/
  sops = {
    defaultSopsFile = "${secretsFile}";
    # defaultSopsFile = ../../../secrets/secrets.yaml;
    validateSopsFiles = true;
    # generate a new key if none is found
    generateKey = true;
    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/home/administrator/.ssh/ssh_host_ed25519_key"
      ];
      # sshKeyPaths = map getKeyPath keys;
      # this will use an age key that is expected already in the fs.
      keyFile = "/var/lib/sops-nix/keys.txt";
    };

  };
}
