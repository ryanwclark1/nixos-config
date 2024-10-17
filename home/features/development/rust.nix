{
  config,
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
      cargo-sweep
      cargo-audit
      cargo-tarpaulin
      cargo-semver-checks
      cargo-udeps
      cargo-watch
      cargo-edit
      cargo-update
      cargo-release
      cargo-modules
      cargo-generate
      cargo-workspaces
      cargo-public-api
      cargo-nextest
      cargo-leptos
    ];

    rustBasics = [
      rustup
      cargo-binutils
    ];

    utils = [
      rust-analyzer
      rust-audit-info
      rust-code-analysis
      rust-script
      taplo
      trunk # for wasm
    ];
  in
  rustBasics
  ++ cargoSubCommands
  ++ rustBasics
  ++ externalLibs
  ++ utils;

  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" "${config.home.homeDirectory}/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin" ];

}
