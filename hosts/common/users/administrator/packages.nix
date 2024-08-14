{
  pkgs,
  ...
}:

# Change so this is set at the machine/host level
{
  users.users.administrator.packages = with pkgs; [
    google-chrome
  ];
}
