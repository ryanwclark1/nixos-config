# An extremely fast Python package and project manager, written in Rust.
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
