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
    # config = {
    #   theme = "Nord";
    # };
  };

  home.shellAliases = {
    cat = "bat";
  };

}
