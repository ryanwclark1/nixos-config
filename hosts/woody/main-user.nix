{
  lib,
  config,
  pkgs,
  ...
}:

{
  options = {
    main-user.enable = lib.mkEnableOption "enable user module";

    main-user.userName = lib.mkOption {
      default = "administrator";
      description = ''
        username
      '';
    };
  };
  config = lib.mkIf config.main-user.enable {
    users.users."administrator" = {
      isNormalUser = true;
      # initialPassword = "";
      description = "Administrator User";
      shell = pkgs.zsh;
      extraGroups = [ "networkmanager" "wheel" "audio" "docker" "video" "transmission" "wireshark"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJx3Sk20pLL1b2PPKZey2oTyioODrErq83xG78YpFBoj admin@xxxx"
      ];
      packages = with pkgs; [
        google-chrome
       #  thunderbird
      ];
    };
    programs.zsh.enable = true;
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark-cli;
    };
  };
}
