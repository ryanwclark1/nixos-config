{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    minikube
    openlens
    tilt
    kubeshark
  ];
}