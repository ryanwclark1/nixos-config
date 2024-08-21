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
      # qemu
      clang
      glib
      grub2
      openssl
      pkg-config
      xorriso
      zlib.out
    ];

    utils = [
      # rust-analyzer
      bunyan-rs
      lapce
      lldb
      mdbook
      rust-audit-info
      rust-code-analysis
      rust-script
      rusty-man
      sea-orm-cli
      sqlite
      sqlx-cli
      taplo
      trunk # for wasm
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
