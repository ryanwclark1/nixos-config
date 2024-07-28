{
  pkgs,
  ...
}:

{
  virtualisation.arion = {
    backend = "docker";
    projects = {
      "semaphore".settings.services."semaphore".service = {
        image = "semaphoreui/semaphore:latest";
        restart = "unless-stopped";
        ports = [
          "3000:3000"
        ];
        environment = {
          SEMAPHORE_DB_DIALECT="bolt";
          SEMAPHORE_ADMIN_PASSWORD="changeme";
          SEMAPHORE_ADMIN_NAME="admin";
          SEMAPHORE_ADMIN_EMAIL="admin@localhost";
          SEMAPHORE_ADMIN="admin";
          TZ="America/Chicago";
        };
        volumes = [
          "/etc/semaphore:/etc/semaphore" # config.json location
          "/var/lib/semaphore:/var/lib/semaphore" # database.boltdb location (Not required if using mysql or postgres)
        ];
      };
    };
  };
}