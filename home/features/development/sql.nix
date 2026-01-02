{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # sqlfluff # Temporarily disabled due to dependency conflict (click version issue)
    pgcli
    sqlite
    lazysql # SQL Tui
  ];
}
