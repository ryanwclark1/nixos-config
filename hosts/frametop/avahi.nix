# ./host/frametop/avahi.nix

{
  services.avahi = {
    openFirewall = true;
    nssmdns = true; # Allows software to use Avahi to resolve.
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };
}
