{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [

    python311
    python311Packages.poetry-core
    python311Packages.pdm-backend
    python311Packages.pip
    # python311Packages.pipx
    # poetry
    functiontrace-server
    memray
  ];
  home.sessionPath = [ "$HOME/.python/bin" ];
}
