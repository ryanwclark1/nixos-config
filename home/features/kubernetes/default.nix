{
  pkgs,
  ...
}:

{
  import = [
    ./k9s.nix
  ];
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    minikube
    openlens
    tilt
    kubeshark
  ];
}
