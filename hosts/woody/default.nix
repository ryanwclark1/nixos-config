{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Hardware modules
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd

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
    ../common/optional/services/syncthing.nix
    ../common/optional/desktop/style.nix
    ../common/optional/desktop/thunar.nix
    ../common/optional/services/virtualisation.nix
    ../common/optional/services/webcam.nix
    ../common/optional/tools/wireshark.nix
    ../common/optional/tools/zsh.nix
    ../common/optional/desktop/hyprland
    ../common/optional/desktop/displaymanager/sddm
  ];

  # Override global monitoring with woody's comprehensive setup
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
        cmdline = [ "prometheus" ];
      }
      {
        name = "{{.Comm}}";
        cmdline = [ "grafana" ];
      }
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
  networking.hostName = "woody";

  # Override boot settings for desktop
  boot = {
    # Override tmp settings for desktop
    tmp.cleanOnBoot = true;

    # Override kernel to use zen kernel for better desktop performance
    # Zen kernel provides better latency and responsiveness for desktop workloads
    kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_zen;

    # Override loader settings for desktop
    # Keep more boot entries for desktop (20 vs global default of 10)
    # - Desktop systems often need more entries for development/testing
    # - Allows for more experimentation with configurations
    # - Provides extended rollback capability for complex setups
    # - Desktop typically has more disk space available
    loader.systemd-boot.configurationLimit = lib.mkForce 20;
  };

  # Desktop-specific power management
  powerManagement = {
    cpuFreqGovernor = "performance";
  };

  system.stateVersion = "24.05";
}
