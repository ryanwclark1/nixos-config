{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.go = {
    enable = true;
    package = pkgs.go; # Use latest stable Go version
  };

  home.packages = with pkgs; [
    air       # Live reload for Go apps
    templ     # A language for writing HTML user interfaces in Go.
    golangci-lint-langserver
    gopls
    errcheck
    delve # debugger for the Go programming language
    gofumpt
    gotestsum # 'go test' runner with output optimized
    golangci-lint
    go-callvis
    go-tools
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
  ];

  # Additional session environment variables for Go
  home.sessionVariables = {
    # Go telemetry settings
    GOTELEMETRY = "off";

    # Go workspace
    GOPATH = "${config.home.homeDirectory}/go";
    GOBIN = "${config.home.homeDirectory}/go/bin";

    # Go module settings
    GOPROXY = "https://proxy.golang.org,direct";
    GOSUMDB = "sum.golang.org";
    GOPRIVATE = "github.com/accent-ai/*,gitlab.com/*";

    # Testing
    GORACE = "halt_on_error=1";
  };

  # Create Go workspace bin directory (only bin is needed for installed tools)
  home.file."${config.home.homeDirectory}/go/bin/.keep".text = "";

  # Go configuration file for default module proxy and sumdb
  xdg.configFile."go/env" = {
    text = ''
      GOTELEMETRY=off
      GOPROXY=https://proxy.golang.org,direct
      GOSUMDB=sum.golang.org
      GOPRIVATE=github.com/accent-ai/*,gitlab.com/*
      GOMODCACHE=${config.home.homeDirectory}/go/pkg/mod
      GOCACHE=${config.home.homeDirectory}/.cache/go-build
      CGO_ENABLED=1
      GOFLAGS=-buildvcs=true
    '';
  };

}
