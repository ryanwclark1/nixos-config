{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sqlfluff
    pgcli
    sqlite
    lazysql # SQL Tui
  ];
}
