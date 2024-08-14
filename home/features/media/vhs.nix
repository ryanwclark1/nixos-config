# Write terminal GIFs as code for integration testing and demoing your CLI tools.
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    vhs
  ];
}
