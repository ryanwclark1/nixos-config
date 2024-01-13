{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    ../common/global
    ../common/users/administrator

    ../common/optional/wireless.nix
    ../common/optional/pipewire.nix
  ];

networking = {
    hostName = "frametop";
    useDHCP = true;
    # firewall.enable = false;
    # nameservers = [
    #   "10.10.100.1"
    #   "9.9.9.9"
    #   "1.1.1.1"
    # ];
    # wireguard.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  powerManagement.powertop.enable = true;
  programs = {
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  # Lid settings
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  hardware ={
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  system.stateVersion = "23.11";
}