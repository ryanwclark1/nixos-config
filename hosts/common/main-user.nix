{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "administrator";
      description = ''
        Administrator User
      '';
    };
  };
  
  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      # initialPassword = "";
      shell = pkgs.zsh;
      extraGroups = [ "networkmanager" "wheel" "audio" "docker" "video" "transmission" "wireshark"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJx3Sk20pLL1b2PPKZey2oTyioODrErq83xG78YpFBoj admin@xxxx"
      ];
      packages = with pkgs; [
        google-chrome
      #   firefox
      #  #  thunderbird
      ];
    };
    programs.zsh.enable = true;
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark-cli;
    };
  };
}
