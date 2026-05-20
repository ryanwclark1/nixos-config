{
  pkgs,
  ...
}:

let
  pgcliWithFixedCliHelpers = pkgs.pgcli.override {
    cli-helpers = pkgs.python313Packages.cli-helpers.overridePythonAttrs (_old: {
      # cli-helpers 2.10.0 has ANSI color expectation tests that fail with the
      # current Pygments stack, but pgcli only needs the runtime library.
      doCheck = false;
    });
  };
in
{
  home.packages = with pkgs; [
    # sqlfluff # Temporarily disabled due to dependency conflict (click version issue)
    # Using uvx alias below instead.
    pgcliWithFixedCliHelpers
    sqlite
    lazysql # SQL Tui
  ];

  home.shellAliases = {
    sqlfluff = "uvx sqlfluff";
  };
}
