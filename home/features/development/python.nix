{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    python312
    python312Packages.pip
    python312Packages.pyaml
    functiontrace-server
  ]) ++ (with pkgs.python312Packages; [
    pip
    pyyaml
  ]);

  programs = {
    poetry = {
      enable = true;
      package = pkgs.poetry.withPlugins (ps: with ps; [ poetry-plugin-up ]);
      settings = {
        virtualenvs.create = true;
        virtualenvs.in-project = true;
      };
    };
  };
}