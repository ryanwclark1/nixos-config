# TODO: add user variable
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  home.packages = with pkgs; [
    # poetry
    python311
    python311Packages.poetry-core
    python311Packages.pdm-backend
    # python311Packages.pipx
    python311Packages.pip
  ];
  home.sessionPath = ["/home/administrator/.python/bin"];
}