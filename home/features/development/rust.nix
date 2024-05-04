{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; let
    cargoSubCommands = [
      cargo-cross
      cargo-clone
      cargo-release
      cargo-vet
      cargo-shuttle
      cargo-temp
      cargo-shuttle
      cargo-sort
      cargo-sweep
      cargo-audit
      cargo-auditable
      cargo-tarpaulin
      cargo-semver-checks
      cargo-udeps
      cargo-watch
      cargo-crev
      cargo-deny
      cargo-diet
      cargo-edit
      cargo-bloat
      cargo-about
      cargo-update
      cargo-readme
      cargo-release
      cargo-modules
      cargo-profiler
      cargo-outdated
      cargo-generate
      cargo-workspaces
      cargo-public-api
      cargo-supply-chain
      cargo-unused-features
      cargo-nextest
      cargo-leptos
    ];

    rustBasics = [
      # llvmPackages_latest.bintools
      # llvmPackages_latest.lld
      # llvmPackages_latest.llvm
      rustup
      cargo-binutils
    ];

    externalLibs = [
      glib
      grub2
      clang
      openssl
      # qemu
      zlib.out
      xorriso
      pkg-config
    ];

    utils = [
      lldb
      mdbook
      # rust-analyzer
      taplo
      rusty-man
      rust-audit-info
      lapce
      rust-code-analysis
      trunk # for wasm
      sea-orm-cli
      sqlx-cli
      bunyan-rs
      rust-script
      sqlite
      valgrind
    ];
  in
  cargoSubCommands
  ++ rustBasics
  ++ externalLibs
  ++ utils;

  home.sessionVariables = {
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  };
  home.sessionPath = [ "$HOME/.cargo/bin" "/$HOME/administrator/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin" ];

}
