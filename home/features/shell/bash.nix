{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enhanced bash configuration with modern tooling
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

}
