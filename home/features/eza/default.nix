# A modern, maintained replacement for ls.
{
  ...
}:

{
  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}