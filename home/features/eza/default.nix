# A modern, maintained replacement for ls.
{
  ...
}:

{
  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    enableAliases = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--total-size" # unix only
    ];
  };
}