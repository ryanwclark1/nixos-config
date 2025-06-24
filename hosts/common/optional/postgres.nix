# https://mynixos.com/nixpkgs/options/services.postgresql
{
  ...
}:

{
  services.postgresql = {
    enable = false;
  };
  # environment.persistence = {
  #   "/persist".directories = ["/var/lib/postgresql"];
  # };
}
