{
  config,
  lib,
  outputs,
  pkgs,
  ...
}:
let
  hosts = lib.attrNames outputs.nixosConfigurations;
  user = "administrator";
  homeDirectory = "/home/${user}";
  domain = config.networking.domain;
  # hasOptinPersistence = config.environment.persistence ? "/persist";
in
{
  services = {
    openssh = {
      enable = lib.mkDefault true;
      allowSFTP = lib.mkDefault true;
      openFirewall = lib.mkDefault true;
      startWhenNeeded = lib.mkDefault true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = lib.mkDefault "no";
        # Security hardening while allowing password auth
        MaxAuthTries = 3;
        LoginGraceTime = 60;
        MaxStartups = "10:30:60";
        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";
        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
        # Let WAYLAND_DISPLAY be forwarded
        AcceptEnv = "WAYLAND_DISPLAY";
        X11Forwarding = true;
        # Additional security
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };

      hostKeys = [
        {
          # path = "${lib.optionalString hasOptinPersistence "/persist"}${homeDirectory}/.ssh/ssh_host_ed25519_key";
          path = "${homeDirectory}/.ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };

  programs.ssh = {
    # Each hosts public key
    knownHosts = lib.genAttrs hosts (hostname: {
      publicKeyFile = ../../../${hostname}/ssh_host_ed25519_key.pub;
      extraHostNames =
        [
          "${hostname}.${domain}"
        ]
        ++
          # Alias for localhost if it's the same host
          (lib.optional (hostname == config.networking.hostName) "localhost")
        ++ (lib.optionals (hostname == "woody") [
          "${domain}"
          "local.${domain}"
        ])
        ++ (lib.optionals (hostname == "frametop") [
          "${domain}"
          "local.${domain}"
        ]);
    });
  };

  # Passwordless sudo when SSH'ing with keys
  # security.pam.sshAgentAuth = {
  #   enable = true;
  #   authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
  # };
  # Passwordless sudo when SSH'ing with keys
  security.pam.services.sudo =
    { config, ... }:
    {
      rules.auth.rssh = {
        order = config.rules.auth.ssh_agent_auth.order - 1;
        control = "sufficient";
        modulePath = "${pkgs.pam_rssh}/lib/libpam_rssh.so";
        settings.authorized_keys_command = pkgs.writeShellScript "get-authorized-keys" ''
          cat "/etc/ssh/authorized_keys.d/$1"
        '';
      };
    };
  # Keep SSH_AUTH_SOCK when sudo'ing
  security.sudo.extraConfig = ''
    Defaults env_keep+=SSH_AUTH_SOCK
  '';

}
