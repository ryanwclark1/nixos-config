{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sqlfluff
    dbeaver-bin
    pgcli
    sqlitebrowser
  ];
}
