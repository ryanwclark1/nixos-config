{ pkgs, inputs, ... }: {
  imports = [

    inputs.hardware.nixosModules.common-pc-ssd
    inputs.vscode-server.nixosModules.default
    ./hardware-configuration.nix
    ../common/global

    ../common/users/administrator

    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/nfs.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/k3s.nix

    ../common/optional/gnome

  ];

  networking = {
    hostName = "woody";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  services = {
    vscode-server = {
      enable = true;
    };
    xserver.videoDrivers = [ "amdgpu" ];
  };

  hardware = {
    # opengl = {
    #   enable = true;
    #   driSupport = true;
    #   driSupport32Bit = true;
    # };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    gcc
  ];

  system.stateVersion = "23.11";
}
