{
  pkgs,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go_1_23;
    goPath = "go";
  };

  home.packages = with pkgs; [
    golangci-lint-langserver
    gopls
    errcheck
    templ
  ];
  # home.sessionPath = [ "$HOME/go/bin" ];
}
