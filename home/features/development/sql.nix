{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sqlfluff
    pgcli
    sqlite
  ];
}
