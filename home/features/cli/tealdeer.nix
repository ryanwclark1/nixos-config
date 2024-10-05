# Tealdeer is a very fast implementation of tldr 
{
  ...
}:

{
  programs.tealdeer = {
    enable = true;
    settings = {
      display = {
        compact = false;
        use_pager = true;
      };
      updates = {
        auto_update = false;
        auto_update_interval_hours = 240;
      };
    };
  };
}