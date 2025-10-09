# ./host/common/global/virtualisation.nix
{
  ...
}:

{
  # Virtualisation configuration
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      qemu = {
        # All OVMF images distributed with QEMU are now available by default
        # ovmf = {
        #   enable = true;
        # };
        # virtual tpm
        swtpm.enable = true;
      };
    };
    # USB redirection support
    spiceUSBRedirection.enable = true;
  };
  programs.virt-manager = {
    enable = true;
  };

}
