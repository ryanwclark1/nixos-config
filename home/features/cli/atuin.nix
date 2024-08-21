# Terminal history search
# https://atuin.sh/docs/
# Updated when enter is pressed select not execute.

{
  pkgs,
  ...
}:

{
  programs.atuin = {
    enable = true;
    package = pkgs.atuin;
    flags = [
      "--disable-up-arrow"
    ];

    settings = {
      auto_sync = false;
      sync_frequency = "10m";
      search_mode = "fuzzy";
      # sync_address = "https://atuin.techcasa.io";
    };

  };
}
