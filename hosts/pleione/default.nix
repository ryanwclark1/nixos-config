{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix

    ../common/global
    ../common/users/administrator

    ../common/optional/wireless.nix
    ../common/optional/greetd.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    ../common/optional/lol-acfix.nix
  ];

  networking = {
    hostName = "pleione";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  powerManagement.powertop.enable = true;
  programs = {
    light.enable = true;
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  # Lid settings
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  hardware.opengl.enable = true;

  system.stateVersion = "22.05";
}
