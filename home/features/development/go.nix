{
  pkgs,
  ...
}:

{

  programs.go = {
    enable = true;
    package = pkgs.go_1_21;
    packages = {
      # "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
    };
    goPath = "go";
  };

  home.packages = with pkgs; [
    richgo
    golangci-lint-langserver
    ent-go
    go-tools
    gocode
    gopls
    godef
    gotools
    errcheck
  ];

  home.sessionPath = ["$HOME/go/bin"];

}
