{
  config,
  ...
}:

{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };
      cmd_duration = {
        min_time = 5000;
      };
      # Default w/o Nerd Fonts https://github.com/starship/starship/pull/3544

    };
  };
}
