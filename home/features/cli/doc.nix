{
  lib,
  config,
  ...
}:
with lib; {
  programs = {
    info.enable = true;
    tealdeer.enable = true;
    man = {
      enable = true;
      generateCaches = true;
    };
  };
}