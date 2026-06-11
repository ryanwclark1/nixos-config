{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    python313
    (pipx.overrideAttrs (old: { doCheck = false; pytestCheckPhase = "true"; checkPhase = "true"; }))
    functiontrace-server
  ]) ++ (with pkgs.python313Packages; [
    pip
    pyyaml
  ]);

}
