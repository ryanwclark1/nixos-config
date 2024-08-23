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
    # flags = [
    #   "--disable-up-arrow"
    # ];
    # https://docs.atuin.sh/configuration/config/
    settings = {
      # sync_address = "https://atuin.techcasa.io";
      auto_sync = true;
      sync_frequency = "1m";
      search_mode = "fuzzy";
      dialect = "us";
      update_check = true;
      filter_mode = "global";
      search_mode_shell_up_key_binding = "fuzzy";
      filter_mode_shell_up_key_binding = "global";
      style = "auto";
      show_preview = true;
      max_preview_height = 4;
      show_help = true;
      show_tabs = true;
      exit_mode = "return-original";
      history_format = "history list";
      store_failed = true;
      secrets_filter = false;
      enter_accept = false;
      # TODO: Switch to vim-normal?
      keymap_mode = "vim-normal";
      prefers_reduced_motion = false;
    };

  };
}
