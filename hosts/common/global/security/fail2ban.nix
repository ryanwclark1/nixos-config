{
  lib,
  ...
}:

{
  services.fail2ban = {
    enable = lib.mkDefault true;
    maxretry = 3;  # Reduced from 5 for better security
    bantime = "1h"; # Increased from 30m
    # findtime = "10m";

    # jails = {
    #   # Enhanced SSH protection
    #   sshd = {
    #     enable = true;
    #     filter = "sshd";
    #     action = "iptables[name=SSH, port=ssh, protocol=tcp]";
    #     maxretry = 3;
    #     findtime = "10m";
    #     bantime = "1h";
    #   };
    # };
  };
}
