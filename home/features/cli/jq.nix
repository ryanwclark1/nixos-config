# A lightweight and flexible command-line JSON processor

{
  config,
  lib,
  ...
}:
with lib; {
  programs.jq = {
    enable = true;
  };
}