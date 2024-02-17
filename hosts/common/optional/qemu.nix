# ./host/common/global/virtualisation.nix
{ pkgs
, ...
}:

{
  # Virtualisation configuration
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      qemu = {
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
        # virtual tpm
        swtpm.enable = true;
      };
    };
    # USB redirection support
    spiceUSBRedirection.enable = true;
  };
}
