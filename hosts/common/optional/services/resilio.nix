{
  config,
  ...
}:

{
  services.resilio = {
    enable = true;
    deviceName = config.networking.hostName;
    checkForUpdates = true;
    enableWebUI = false;
  };
}