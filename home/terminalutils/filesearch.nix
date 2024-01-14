{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.filesearch.enable = mkEnableOption "file search settings";

  config = mkIf config.filesearch.enable {
    home.packages = with pkgs; [
      fd
      # ripgrep-all
      ripgrep
      sd
    ];
    programs.eza = {
      enable = true;
      icons = true;
      git = true;
      enableAliases = true;
    };
    programs.zoxide = {
      enable = true;
    };
  };
}