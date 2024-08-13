{
  pkgs,
  ...
}:

{
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