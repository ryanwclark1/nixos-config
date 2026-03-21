{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.fprintd = {
    enable = true;
    package = pkgs.fprintd;
  };

  # Quickshell lock (LockContext.qml) uses PamContext with service name fprintd-verify;
  # NixOS does not ship this file by default unlike some other distros.
  security.pam.services.fprintd-verify = lib.mkIf config.services.fprintd.enable { };
}
