{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.vscode-server.nixosModules.default
    ./hardware-configuration.nix
    ../common/global

    ../common/users/administrator

    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/fail2ban.nix
    ../common/optional/nfs.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix

    ../common/optional/plasma
  ];

  networking = {
    hostName = "frametop";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  powerManagement.powertop.enable = true;

  programs = {
    adb.enable = true;
    dconf.enable = true;
    # kdeconnect.enable = true;
  };

  services = {
    fwupd.enable = true;
    fprintd = {
      enable = true;
    };
    logind = {
      # Lid settings
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
    };
    vscode-server = {
      enable = true;
    };
  };

  hardware = {
    opengl = {
      enable = true;
    #   driSupport = true;
    #   driSupport32Bit = true;
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  security.pam.services.login.fprintAuth = true;

  # Enable Wayland support
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    # EC-Tool adjusted for usage with framework embedded controller.
    fw-ectool
    gcc
  ];


  system.stateVersion = "23.11";
}
