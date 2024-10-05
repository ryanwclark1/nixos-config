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
      ".env/"
      ".venv/"
      "node_modules/"
    ];
    extraOptions = [
      "--absolute-path"
    ];
  };

}