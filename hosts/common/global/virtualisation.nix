# ./host/common/global/docker.nix

{
  # Virtualisation configuration
  virtualisation = {
    # Libvirt specific settings
    libvirtd = {
      enable = true;
      # Qemu settings
      qemu.ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      # Virtual TPM
      qemu.swtpm.enable = true;
    };
    # USB redirection support
    spiceUSBRedirection.enable = true;
  };
}
