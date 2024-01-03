{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options.ranger.enable = mkEnableOption "ranger settings";

  config = mkIf config.ranger.enable {
    home.packages = with pkgs; [
      ranger
    ];
    programs.pistol = {
      enable = true;
      associations = [
        {
          mime = "text/*";
          command = "${config.terminal} ${config.editor.terminal} &pistol-filename%";
        }
        {
          mime = "text/x-go";
          command = "${config.terminal} ${config.editor.terminal} &pistol-filename%";
        }
      ];
    };
  };
}