{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    python312
    functiontrace-server
  ]) ++ (with pkgs.python312Packages; [
    pip
    pyyaml
  ]);

}
