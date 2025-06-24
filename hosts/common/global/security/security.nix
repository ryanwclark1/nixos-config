{
  lib,
  ...
}:

{
  security = {
    # Enable audit system
    auditd.enable = true;
    audit.enable = true;

    # Enable real-time scheduling
    rtkit.enable = true;

    # Enable polkit
    polkit.enable = true;

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
