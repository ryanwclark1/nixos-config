{
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Hardware modules
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

    # Host-specific files
    ./hardware-configuration.nix
    ./services
    ./performance.nix
    ./monitoring

    # Common configurations
    ../common/global
    ../common/users/administrator

    # Optional features
    ../common/optional/services/audio.nix
    ../common/optional/services/bluetooth.nix
    ../common/optional/tools/direnv.nix
    ../common/optional/tools/fonts.nix
    ../common/optional/services/gnome-services.nix
    ../common/optional/desktop/nautilus.nix
    ../common/optional/services/nfs.nix
    ../common/optional/services/printing.nix
    ../common/optional/services/steam.nix
    ../common/optional/desktop/thunar.nix
    ../common/optional/services/virtualisation.nix
    ../common/optional/services/webcam.nix
    ../common/optional/tools/wireshark.nix
    ../common/optional/tools/zsh.nix
    ../common/optional/desktop/displaymanager/sddm
    ../common/optional/desktop/hyprland
  ];

  # Override global monitoring with frametop's comprehensive setup
  services.prometheus.exporters.node = lib.mkForce {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "cpu"
      "diskstats"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "netstat"
      "textfile"
      "time"
      "uname"
      "vmstat"
      "logind"
      "interrupts"
      "ksmd"
      "processes"
      "systemd"
      "filefd"
      "hwmon"
      "mountstats"
      "sockstat"
      "stat"
    ];
    extraFlags = [
      "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)"
      "--collector.filesystem.ignored-fs-types=^(sys|proc|auto)fs$$"
    ];
  };

  services.prometheus.exporters.process = lib.mkForce {
    enable = true;
    port = 9256;
    settings.process_names = [
      {
        name = "{{.Comm}}";
        cmdline = [ "node_exporter" ];
      }
      {
        name = "{{.Comm}}";
        cmdline = [ "systemd_exporter" ];
      }
      {
        name = "{{.Comm}}";
        cmdline = [ "cadvisor" ];
      }
      {
        name = "{{.Comm}}";
        cmdline = [ "process_exporter" ];
      }
    ];
  };

  # Host-specific settings
  networking.hostName = "frametop";

  # Override boot settings for laptop
  boot = {
    # Disable tmp cleaning for laptop
    tmp.cleanOnBoot = false;

    # Note: Uses global configurationLimit of 10 boot entries
    # - Appropriate for laptop systems with limited disk space
    # - Still provides sufficient rollback capability for normal use
    # - Balances functionality with storage constraints
    # - Can be overridden if needed for specific laptop use cases

    # Enable binary format support
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
  };

  # Laptop-specific power management
  powerManagement = {
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  # Framework-specific security settings
  security.pam.services.login.fprintAuth = lib.mkForce true;

  # Framework-specific packages
  environment.systemPackages = with pkgs; [
    fw-ectool # EC-Tool adjusted for usage with framework embedded controller
  ];

  system.stateVersion = "24.11";
}
