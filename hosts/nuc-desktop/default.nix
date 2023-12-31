 # nuc-desktop configuration.nix
 { config, pkgs, ... }:

{

  networking.hostName = "nucdesktop";

  services.xserver.desktopManager.gnome3.enable = true;

  users.users.administrator = {
    isNormalUser = true;
    home = "/home/administrator";
    extraGroups = ["networkmanager" "wheel", "docker"];
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Add common packages to system-wide environment
  # environment.systemPackages = with pkgs; (import ../../common-packages.nix);

  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Enable CUPS printing service
  services.printing.enable = true;

  # Set default EDITOR environment variable to neovim
  environment.variables.EDITOR = "${pkgs.neovim}/bin/nvim";

  # Allow unfree software
  nixpkgs.config.allowUnfree = true;

}

