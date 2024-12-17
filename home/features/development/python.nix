{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    python312
    functiontrace-server
  ]) ++ (with pkgs.python312Packages; [
    pip
    pyyaml
  ]);

  programs = {
    poetry = {
      enable = false;
      package = pkgs.poetry.withPlugins (ps: with ps; [ poetry-plugin-up ]);
      settings = {
        virtualenvs.create = true;
        virtualenvs.in-project = true;
      };
    };
  };
}