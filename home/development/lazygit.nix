{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.lazygit.enable = mkEnableOption "lazygit settings";

  config = mkIf config.lazygit.enable {
    programs.lazygit = {
      enable = true;
    };
  };
}
