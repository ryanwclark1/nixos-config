{
  pkgs,
  ...
}:

{
  environment.pathsToLink = [ "/share/zsh" ];

  programs.zsh = {
    enable = true;
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestions = {
      enable = true;
    };
    enableBashCompletion = true;
    enableCompletion = true;
    enableGlobalCompInit = true;
    enableLsColors = true;

  };
}
