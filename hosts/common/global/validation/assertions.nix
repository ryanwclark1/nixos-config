{
  config,
  lib,
  ...
}:

{
  # Configuration assertions and validations
  assertions = [
    # Security assertions
    {
      assertion = config.networking.firewall.enable;
      message = "Firewall must be enabled on all hosts for security";
    }
    {
      assertion = config.security.auditd.enable;
      message = "Audit system must be enabled on all hosts for compliance";
    }
    {
      assertion = config.services.openssh.enable;
      message = "SSH must be enabled for remote access";
    }

    # System assertions
    {
      assertion = config.services.timesyncd.enable;
      message = "Time synchronization must be enabled";
    }
    {
      assertion = config.i18n.defaultLocale == "en_US.UTF-8";
      message = "Default locale must be set to en_US.UTF-8";
    }

    # Network assertions
    {
      assertion = config.networking.networkmanager.enable;
      message = "NetworkManager must be enabled for network connectivity";
    }
    {
      assertion = config.services.resolved.enable;
      message = "systemd-resolved must be enabled for DNS resolution";
    }

    # Nix assertions
    {
      assertion =
        config.nix.settings.experimental-features == [
          "nix-command"
          "flakes"
        ];
      message = "Nix experimental features must include nix-command and flakes";
    }
    {
      assertion = config.nix.gc.automatic || config.programs.nh.clean.enable;
      message = "Either automatic Nix garbage collection or nh cleanup must be enabled";
    }
  ];

  # Warnings for configuration issues
  warnings = [
    # Warn about potential security issues
    (lib.optionalString (
      !config.security.rtkit.enable
    ) "RTKit is not enabled - real-time scheduling may be limited")

    # Warn about performance settings
    (lib.optionalString (
      !config.services.fstrim.enable
    ) "fstrim is not enabled - SSD performance may degrade over time")

    # Warn about monitoring
    (lib.optionalString (
      !config.services.prometheus.exporters.node.enable
    ) "Prometheus node exporter is not enabled - system monitoring may be limited")
  ];
}
