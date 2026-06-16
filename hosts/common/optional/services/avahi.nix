{ ... }:

{
  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true; # Allows software to use Avahi to resolve .local names.
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };
}
