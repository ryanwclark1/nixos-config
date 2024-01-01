{
  config,
  ...
}:

{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
  };
}
