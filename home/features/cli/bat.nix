{
  pkgs,
  ...
}:

{
  programs.bat = {
    enable = true;
    package = pkgs.bat;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batgrep
      batman
      batpipe
      batwatch
      prettybat
    ];
  };

  home.shellAliases = {
    cat = "bat";
  };
}
