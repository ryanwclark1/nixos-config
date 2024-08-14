{
  lib,
  ...
}:

{
  services = {
    fail2ban = {
      enable = lib.mkDefault true;
      maxretry = 5;
      bantime = "30m";
    };
  };

}