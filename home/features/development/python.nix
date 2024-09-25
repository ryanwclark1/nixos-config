{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    python312
    python312Packages.poetry-core
    python312Packages.pdm-backend
    python312Packages.pip
    # python312Packages.pipx
    # poetry
    functiontrace-server
    # memray
  ];
  # home.sessionPath = [ "$HOME/.python/bin" ];
}
