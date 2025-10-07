{
  config,
  pkgs,
  ...
}:

{

  networking.firewall = {
    allowedTCPPorts = [
      3000 # openvscode-server
    ];
  };

  services.openvscode-server = {
    enable = true;
    # connectionToken = config.sops.secrets.openvscode-server-connection-token.path;
    # connectionTokenFile = config.sops.secrets.openvscode-server-connection-token.path;
    # extraArguments = [ "--port" "3000" ];
    # extraEnvironment = {
    #   PATH = "${config.home.homeDirectory/.openvscode-server/bin:$PATH}";
    # };
    extraGroups = [ "docker" ];
    extraPackages = [ pkgs.go ];
    group = "openvscode-server";
    host = "localhost";
    port = 3000;
    telemetryLevel = "off";
    withoutConnectionToken = true;
  };
}
