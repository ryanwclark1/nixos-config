# https://mynixos.com/nixpkgs/options/services.postgresql
{
  ...
}:

{
  services.postgresql = {
    enable = true;
  };
  # environment.persistence = {
  #   "/persist".directories = ["/var/lib/postgresql"];
  # };
}