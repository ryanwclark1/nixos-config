{
  lib,
  ...
}:

{
  security = {
    # Enable audit system
    auditd.enable = lib.mkDefault true;
    audit.enable = lib.mkDefault true;

    # Enable real-time scheduling
    rtkit.enable = lib.mkDefault true;

    # Enable polkit
    polkit.enable = lib.mkDefault true;

    # Increase open file limit for sudoers
    pam.loginLimits = [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "524288";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "1048576";
      }
    ];
  };
}
