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
    GOTELEMETRY = "off"; # Disable telemetry completely
    GOTELEMETRYDIR = "${config.home.homeDirectory}/.cache/go-telemetry"; # Telemetry data directory if enabled
    
    # Go workspace
    GOPATH = "${config.home.homeDirectory}/go";
    GOBIN = "${config.home.homeDirectory}/go/bin";
    
    # Go module settings
    GOPROXY = "https://proxy.golang.org,direct";
    GOSUMDB = "sum.golang.org";
    GOPRIVATE = "github.com/accent-ai/*,gitlab.com/*";
    GO111MODULE = "on";
    
    # Build performance
    GOMAXPROCS = "0"; # Use all available CPU cores (0 = auto)
    
    # Testing
    GORACE = "halt_on_error=1";
  };

  home.file."${config.home.homeDirectory}/go/bin/gopls".source = "${pkgs.gopls}/bin/gopls";
  home.file."${config.home.homeDirectory}/go/bin/staticcheck".source = "${pkgs.go-tools}/bin/staticcheck";

  # Create Go workspace directories
  home.file."${config.home.homeDirectory}/go/src/.keep".text = "";
  home.file."${config.home.homeDirectory}/go/pkg/.keep".text = "";
  home.file."${config.home.homeDirectory}/go/bin/.keep".text = "";
  
  # Go configuration file for default module proxy and sumdb
  home.file."${config.home.homeDirectory}/.config/go/env" = {
    text = ''
      GOTELEMETRY=off
      GOTELEMETRYDIR=${config.home.homeDirectory}/.cache/go-telemetry
      GO111MODULE=on
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
