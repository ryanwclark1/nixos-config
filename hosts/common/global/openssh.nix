{
  config,
  lib,
  # outputs,
  ...
}:

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
      # Allow forwarding ports to everywhere
      # GatewayPorts = "clientspecified";
      };

      hostKeys = [{
        path = "${config.home.homeDirectory}/.ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
    };
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
