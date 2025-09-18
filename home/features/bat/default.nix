{
  pkgs,
  ...
}:

{
  imports = [
    ./theme.tmTheme.nix
  ];

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
    config = {
      pager = "less -FR";
      theme = "theme";
    };
  };

  home.shellAliases = {
    cat = "bat --plain --color=always";
    # Note: batpipe is automatically used by less through LESSOPEN
    # configured in shell/common.nix
  };

  # home.file.".config/bat/themes/test.tmTheme" = {
  #   source = ./test.tmTheme;
  #   executable = false;
  # };
}
