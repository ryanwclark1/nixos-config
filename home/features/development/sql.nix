{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sqlfluff
    dbeaver-bin
    mycli
    pgcli
    sqlitebrowser
  ];
}
