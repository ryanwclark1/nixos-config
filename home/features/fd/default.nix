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
      "*.bak"
    ];
    # extraOptions = [];
  };
}