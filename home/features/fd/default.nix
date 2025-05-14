{
  pkgs,
  ...
}:

{
  programs.fd = {
    enable = true;
    package = pkgs.fd;
    hidden = true;
    ignores = [
      ".git/"
      ".env/"
      ".venv/"
      "node_modules/"
    ];
    extraOptions = [
      "--color auto"
      "--follow"
      "--no-require-git"
      "--hyperlink auto"
    ];
  };
}
