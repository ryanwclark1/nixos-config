{
  pkgs,
  ...
}:

{
  users.users.administrator.packages = with pkgs; [
    google-chrome
  ];
}
