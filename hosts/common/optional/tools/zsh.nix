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
    enableBashCompletion = false;
    enableCompletion = true;
    enableGlobalCompInit = true;
  };
}
