# A modern, maintained replacement for ls.
{
  lib,
  config,
  pkgs,
  ...
}:

{
  programs.uv = {
    enable = true;
    package = pkgs.uv;
    settings = {
      python-preference = "managed";
    };
  };
}
