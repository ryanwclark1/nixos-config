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
    less = "bat --pager --style=numbers --color=always";
  };

  # home.file.".config/bat/themes/test.tmTheme" = {
  #   source = ./test.tmTheme;
  #   executable = false;
  # };
}
