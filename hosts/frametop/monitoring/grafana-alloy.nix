{
  pkgs,
  config,
  lib,
  ...
}:

{
  # Create the Alloy configuration file with enhanced features
  environment.etc."alloy/config.alloy" = {
    source = ./alloy/config.alloy;
  };

  environment.etc."alloy/blackbox.yml" = {
    source = ./alloy/blackbox.yml;
  };

  environment.etc."alloy/snmp.yml" = {
    source = ./alloy/snmp.yml;
  };

  services.alloy = {
    enable = true;
    configPath = "/etc/alloy";
    extraFlags = [
      "--disable-reporting"
    ];
  };

  # Give Alloy supplementary groups to read process and system information
  systemd.services.alloy.serviceConfig = {
    SupplementaryGroups = [ "systemd-journal" "docker" ];
    # Add capabilities for process monitoring
    AmbientCapabilities = [ "CAP_SYS_PTRACE" "CAP_DAC_READ_SEARCH" ];
    CapabilityBoundingSet = [ "CAP_SYS_PTRACE" "CAP_DAC_READ_SEARCH" ];
  };

  # Open firewall for Alloy
  networking.firewall.allowedTCPPorts = [ 12345 ];
}
