{
  pkgs,
  ...
}:

{
  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true; # Allows software to use Avahi to resolve.
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };

  # Cupsd configuration for printing
  services.printing = {
    enable = true;
    browsing = true;
    drivers = with pkgs; [ hplipWithPlugin ];
  };

}
