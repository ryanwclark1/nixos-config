{
  pkgs,
  lib,
  config,
  ...
}:

{
  home.packages = with pkgs; [
    # cloud native
    kubectl
    kubernetes-helm
    minikube
    openlens
    tilt
  ];
}