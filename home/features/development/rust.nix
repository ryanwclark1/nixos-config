{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; let
    cargoSubCommands = [
      cargo-leptos
    ];

    rustBasics = [
      rustup
      cargo-binutils
    ];

    utils = [
      rust-script
      trunk # for wasm
    ];
  in
  cargoSubCommands
  ++ rustBasics
  ++ utils;

  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" "${config.home.homeDirectory}/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin" ];

}
