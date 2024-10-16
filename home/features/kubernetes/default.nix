{
  pkgs,
  ...
}:

{
  imports = [
    ./k9s.nix
  ];
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    minikube
    talosctl
  ];
}
