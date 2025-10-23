{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./k9s.nix
  ];

  # Create .kube directory for kubeconfig
  home.file.".kube/.keep".text = "";

  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    minikube
    talosctl
    kubeshark # Kubernetes packet capture tool
    seabird # Kubernetes native desktop app that simplifies working with Kubernetes.
    weave-gitops # GitOps for Kubernetes
    tilt # Local Kubernetes development Local to manage your developer instance when your team deploys to Kubernetes in production.
    stern # Multi-pod and container log tailing
    kustomize # Kubernetes native configuration management
    kubectx # Switch between Kubernetes contexts (includes kubens)
  ];

  # Note: Kubernetes aliases are now defined in common.nix to avoid duplication
  # This ensures consistent aliases across all shells

  # Enable kubectl completion for supported shells
  programs.bash.initExtra = lib.mkIf config.programs.bash.enable ''
    # Kubectl completion
    if command -v kubectl &> /dev/null; then
      source <(kubectl completion bash)
      complete -F __start_kubectl k
    fi

    # Minikube completion
    if command -v minikube &> /dev/null; then
      source <(minikube completion bash)
    fi

    # Helm completion
    if command -v helm &> /dev/null; then
      source <(helm completion bash)
    fi
  '';

  programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
    # Kubectl completion
    if command -v kubectl &> /dev/null
      kubectl completion fish | source
    end

    # Minikube completion
    if command -v minikube &> /dev/null
      minikube completion fish | source
    end

    # Helm completion
    if command -v helm &> /dev/null
      helm completion fish | source
    end
  '';

  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
    # Kubectl completion
    if command -v kubectl &> /dev/null; then
      source <(kubectl completion zsh)
      compdef __start_kubectl k
    fi

    # Minikube completion
    if command -v minikube &> /dev/null; then
      source <(minikube completion zsh)
    fi

    # Helm completion
    if command -v helm &> /dev/null; then
      source <(helm completion zsh)
    fi
  '';
}
