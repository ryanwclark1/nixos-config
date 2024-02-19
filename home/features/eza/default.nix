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
    ];
  };
}