{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # sqlfluff
    dbeaver
    mycli
    pgcli
    sqlitebrowser
  ];
}
