# ./host/common/global/virtualisation.nix
{
  pkgs,
  lib,
  ...
}:

with lib; {
  options.qemu.enable = mkEnableOption "qemu settings";

  config = mkIf config.qemu.enable {
    # Virtualisation configuration
    virtualisation = {
      # Libvirt specific settings
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        # Qemu settings
        qemu = {
          ovmf = {
            enable = true;
            # Issue with ovmf
            packages = [ pkgs.OVMFFull.fd ];
          };
          # Virtual TPM
          qemu.swtpm.enable = true;
        };
      };
      # USB redirection support
      spiceUSBRedirection.enable = true;
    };
  };
}
