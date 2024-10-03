{
  pkgs,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go_1_23;
    goPath = "go";
    goBin = "go/bin";
    packages = {
      # "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
      # "github.com/air-verse/air" = builtins.fetchGit { url = "https://github.com/air-verse/air"; ref = "master"; };
      # "github.com/mvdan/gofumpt" = builtins.fetchGit "https://https://github.com/mvdan/gofumpt";
      # "github.com/a-h/templ" = builtins.fetchGit "https://github.com/a-h/templ";
      # "golang.org/x/tools/gopls" = builtins.fetchGit "https://golang.org/x/tools/gopls";
      # "golang.org/x/tools/cmd/goimports" = builtins.fetchGit "https://golang.org/x/tools/cmd/goimports";
      # "github.com/go-delve/delve/cmd/dlv" = builtins.fetchGit "https://github.com/go-delve/delve";
      # "gotest.tools/gotestsum" = builtins.fetchGit "https://github.com/gotestyourself/gotestsum";
    };
  };

  home.packages = with pkgs; [
    air       # Live reload for Go apps
    templ     # A language for writing HTML user interfaces in Go.
    golangci-lint-langserver
    gopls
    errcheck
    delve # debugger for the Go programming language
    gofumpt
    gotestsum
    golangci-lint
    go-callvis
  ];

}
