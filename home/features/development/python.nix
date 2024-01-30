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
  ];
  home.sessionPath = ["$HOME/.python/bin"];
}