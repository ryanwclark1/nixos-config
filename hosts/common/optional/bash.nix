{
  pkgs,
  ...
}:

{
  environment.pathsToLink = [ "/share/bash-completion" ];

  programs = {
    bash = {
      enable = true;
      package = pkgs.bashInteractive;
      blesh = {
        enable = true;
      };
      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };
    };
  };
}