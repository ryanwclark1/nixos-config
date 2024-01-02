# ./host/woody/default.nix
{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./gpu.nix
    ./bluetooth.nix
    ./desktop.nix
    ./networking.nix
    ./ssh.nix
    ../common
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # avoid error
  hardware.pulseaudio.enable = false;

  # Bootloader
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
    kernelModules = [ "nfs" "nfs4" ];
    initrd.kernelModules = [ "amdgpu" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    git
    nfs-utils
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  security.polkit.enable = true;

  services = {
    dbus.packages = [ pkgs.gcr ];
    geoclue2.enable = true;
    gnome.gnome-keyring.enable = true; # libsecret
  };

  system.stateVersion = "23.11";
}

