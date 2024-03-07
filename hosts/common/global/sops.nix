{
  config,
  inputs,
  ...
}:
let
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
    age = {
      sshKeyPaths = map getKeyPath keys;
      # keyFile = "$HOME/.config/sops/age/keys.txt";
      # generateKey = false;
    };
    defaultSopsFile = ../secrets.yml;
  };
}
