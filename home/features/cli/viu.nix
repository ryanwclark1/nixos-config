# A command-line application to view images from the terminal written in Rust.

{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    viu
  ];
}
