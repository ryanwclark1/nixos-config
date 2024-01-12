{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.sql.enable = mkEnableOption "sql settings";

  config = mkIf config.sql.enable {
    home.packages = with pkgs; [
      sqlfluff
      dbeaver
      mycli
      pgcli
    ];
  };
}
