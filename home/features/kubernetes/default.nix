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
  # Note: Using bashrcExtra instead of initExtra to ensure bash completion is loaded first
  programs.bash.bashrcExtra = lib.mkIf config.programs.bash.enable ''
    # Kubectl completion (only if bash completion is available)
    if command -v kubectl &> /dev/null && type complete &> /dev/null; then
      # Filter out invalid shopt commands and source completion
      source <(kubectl completion bash 2>/dev/null | grep -v "shopt.*progcomp" || true)
      # Only set completion if the function exists
      if type __start_kubectl &> /dev/null; then
        complete -F __start_kubectl k 2>/dev/null || true
      fi
    fi

    # Minikube completion
    if command -v minikube &> /dev/null && type complete &> /dev/null; then
      source <(minikube completion bash 2>/dev/null | grep -v "shopt.*progcomp" || true)
    fi

    # Helm completion
    if command -v helm &> /dev/null && type complete &> /dev/null; then
      source <(helm completion bash 2>/dev/null | grep -v "shopt.*progcomp" || true)
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
