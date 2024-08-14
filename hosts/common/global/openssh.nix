{
  # config,
  lib,
  # outputs,
  ...
}:

# let
  # inherit (config.networking) hostName;
  # hosts = outputs.nixosConfigurations;
  # pubKey = host: ../../${host}/ssh_host_ed25519_key.pub;
  # gitHost = hosts."NAME".config.networking.hostName;
# in
{
  services.openssh = {
    enable = lib.mkDefault true;
    allowSFTP = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
    startWhenNeeded = lib.mkDefault true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = lib.mkDefault "no";
    # Allow forwarding ports to everywhere
    # GatewayPorts = "clientspecified";
    };

    hostKeys = [{
      path = "/home/administrator/.ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  services.fail2ban = {
    enable = lib.mkDefault true;
    maxretry = 5;
    bantime = "30m";
  };

#  programs.ssh = { # Each hosts public key
#    knownHosts = builtins.mapAttrs
#      (name: _: {
#        # publicKeyFile = pubKey name;
#        extraHostNames =
#          (lib.optional (name == hostName) "localhost");
#          #  ++ # Alias for localhost if it's the same host
#          # (lib.optionals (name == gitHost) [ "techcasa.io" ]); # Alias for techcasa.io
#      })
#      hosts;
#  };
#
# Passwordless sudo when SSH'ing with keys
  # security.pam.sshAgentAuth = {
  #   enable = true;
  #   authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
  # };


}
