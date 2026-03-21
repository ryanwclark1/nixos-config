{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./boot.nix
    ./system.nix
    ./locale.nix
    ./logging.nix
    ./environment.nix
  ];

  # Tools like OpenAI Codex probe /usr/bin/bwrap (FHS path). NixOS only places
  # /usr/bin/env there by default, so symlink the store bwrap after that step.
  system.activationScripts.bwrapUsrBin = lib.stringAfter [ "usrbinenv" ] ''
    ln -sfn ${pkgs.bubblewrap}/bin/bwrap /usr/bin/bwrap
  '';

  # Common performance-related system packages
  environment.systemPackages = with pkgs; [
    # System monitoring
    btop # Modern system monitor (better than htop)
    htop
    iotop
    nethogs
    smartmontools
    lm_sensors
    s-tui
    upower
    acpi

    # Performance analysis
    sysstat
    perf-tools

    # Hardware tools
    cairo
    sbctl
    pciutils
    usbutils
    lshw
    lsof

    # Sandboxing (Codex CLI checks /usr/bin/bwrap)
    bubblewrap

    # Development tools
    git
    wget
    nodejs_22
    fnm
  ];
}
