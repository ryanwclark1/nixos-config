{
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "/home/administrator/.config/sops/age/keys.txt";

    defaultSopsFile = "../../../../secrets.yaml";
    validateSopsFiles = false;

    secrets = {
      "private_keys/administrator" = {
        path = "/home/administrator/.ssh/id_demo";
      };
    };
  };
}