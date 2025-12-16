{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; let
    # Core Rust toolchain and basics
    rustBasics = [
      # rustup                    # Rust toolchain installer (includes rust-analyzer)
      cargo-binutils           # Utilities for working with binary files
      cargo-expand             # Show macro expansion
      cargo-flamegraph         # Profiling with flamegraphs
      cargo-nextest            # Next-generation test runner
      cargo-watch              # Auto-rebuild on file changes
    ];

    # Development and debugging tools
    devTools = [
      cargo-edit               # Add/remove dependencies from command line
      cargo-outdated           # Check for outdated dependencies
      cargo-audit              # Security audit for dependencies
      cargo-deny               # Lint dependencies for licenses/security
      cargo-generate           # Generate projects from templates
      cargo-make               # Task runner and build tool
      cargo-criterion          # Benchmarking with criterion
      cargo-bloat              # Find what's taking up space in executables
      cargo-udeps              # Find unused dependencies
      cargo-machete            # Remove unused dependencies
    ];

    # Cross-compilation and targets
    crossCompile = [
      cargo-cross              # Cross-compilation tool
    ];

    # Web Assembly and frontend tools
    wasmTools = [
      trunk                    # Build tool for Rust-generated WebAssembly
      wasm-pack                # Build tool for generating WebAssembly packages
      cargo-leptos             # Build tool for Leptos framework
    ];

    # Additional utilities
    utils = [
      rust-script              # Run Rust files as scripts
      bacon                    # Background Rust code checker
      sccache                  # Shared compilation cache
      tokei                    # Count lines of code
    ];

    # System dependencies often needed for Rust projects
    systemDeps = [
      pkg-config               # For finding system libraries
      openssl                  # Common dependency
      sqlite                   # Database
      postgresql               # Database
      protobuf                 # Protocol buffers
    ];
  in
  rustBasics
  ++ devTools
  ++ crossCompile
  ++ wasmTools
  ++ utils
  ++ systemDeps;

  # Environment variables for Rust development
  home.sessionVariables = {
    # Global Rust environment settings
    RUST_BACKTRACE = "1";                    # Always show backtraces
    CARGO_TARGET_DIR = "$HOME/.cargo/target"; # Shared target directory
    RUSTC_WRAPPER = "sccache";               # Use sccache for compilation caching
  };

  # Add cargo bin directory to PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin"
  ];

  # Create minimal cargo configuration for development environment
  home.file.".cargo/config.toml".text = ''
    [net]
    retry = 3
    git-fetch-with-cli = true

    [registries.crates-io]
    protocol = "sparse"

    # Global aliases for development workflow
    [alias]
    b = "build"
    c = "check"
    t = "test"
    r = "run"
    rr = "run --release"
  '';

  # Shell aliases for Rust toolchain management
  home.shellAliases = {
    # Global Rust toolchain commands
    "rust-update" = "rustup update && cargo install-update -a";
    "rust-clean" = "cargo clean && rm -rf ~/.cargo/registry/cache";
  };
}
