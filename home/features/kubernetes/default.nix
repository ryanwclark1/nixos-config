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
    kubeshark # Kubernetes packet capture tool
    seabird # Kubernetes native desktop app that simplifies working with Kubernetes.
    weave-gitops # GitOps for Kubernetes
    tilt # Local Kubernetes development Local to manage your developer instance when your team deploys to Kubernetes in production.
  ];
}
