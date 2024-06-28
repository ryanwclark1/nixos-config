{
  inputs,
  pkgs,
  ...
}:

{
  imports = [

    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/administrator

    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/fail2ban.nix
    # ../common/optional/k3s.nix
    ../common/optional/nfs.nix
    # ../common/optional/nfs-serve.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/theme.nix
    ../common/optional/wireshark.nix

    ../common/optional/displaymanager/gdm.nix
    ../common/optional/gnome
    ../common/optional/hyprland
  ];

  networking = {
    hostName = "woody";
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "keep";
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_6_9;

    # kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_7.override {
    #   argsOverride = rec {
    #     src = pkgs.fetchurl {
    #           url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
    #           sha256 = "sha256-Rp/0a5hoXfE7VsmEF8ZLp6MPikW680qpnweTXhv2XBg=";
    #     };
    #     version = "6.7.8";
    #     modDirVersion = "6.7.8";
    #     };
    # });
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    gitMinimal
    libGL
    inputs.nixos-conf-editor.packages.${system}.nixos-conf-editor
  ];

  system.stateVersion = "24.05";
}
