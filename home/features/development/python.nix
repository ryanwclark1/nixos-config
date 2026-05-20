{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    python313
    pipx
    functiontrace-server
  ]) ++ (with pkgs.python313Packages; [
    pip
    pyyaml
  ]);

}
