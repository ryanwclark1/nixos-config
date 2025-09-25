{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    python313
    functiontrace-server
  ]) ++ (with pkgs.python313Packages; [
    pip
    pyyaml
  ]);

}
