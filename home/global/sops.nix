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
      "accent-email/accent-email-address" = {};
      "accent-email/accent-email-username" = {};
      "accent-email/accent-email-name" = {};
      "accent-email/accent-email-realname" = {};
      "accent-email/accent-email-password" = {};
      "accent-email/accent-email-flavor" = {};
      context7-token = {};
      github-pat = {};
      # Vultr API (commented out - not in secrets.yaml)
      # "vultr/api-key" = {};
      # Sourcebot secrets
      "sourcebot/auth-secret" = {};
      "sourcebot/database/user" = {};
      "sourcebot/database/password" = {};
      "sourcebot/database/name" = {};
      "sourcebot/api-key" = {};
    };
  };
}
