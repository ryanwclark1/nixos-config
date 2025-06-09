{
  pkgs,
  lib,
  ...
}:

{
  boot = {
    # Common boot loader configuration
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "keep";
      };
      efi.canTouchEfiVariables = true;
    };

    # Common kernel settings
    kernelPackages = pkgs.linuxKernel.packages.linux_6_14;

    # Common kernel hardening
    kernel.sysctl = {
      # Security settings
      "kernel.sysrq" = 0;  # Disable magic SysRQ
      "kernel.core_uses_pid" = 1;
      "kernel.ctrl-alt-del" = 0;
      "net.ipv4.tcp_syncookies" = 1;

      # Performance settings
      "vm.swappiness" = lib.mkDefault 10;
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      "net.core.somaxconn" = 65535;
    };
  };
}
