{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  home.packages = with pkgs; [
    # sqlfluff
    dbeaver
    mycli
    pgcli
  ];
}
