# ./host/common/global/virtualisation.nix
{
  pkgs,
  ...
}:


{
  # Virtualisation configuration
  virtualisation = {
    # Libvirt specific settings
    libvirtd = {
      enable = true;
      # Qemu settings
      qemu.ovmf = {
        enable = true;
        # Issue with ovmf
        packages = [ pkgs.OVMFFull.fd ];
      };
      # Virtual TPM
      qemu.swtpm.enable = true;
    };
    # USB redirection support
    spiceUSBRedirection.enable = true;
  };
}
