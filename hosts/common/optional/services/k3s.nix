{
  pkgs,
  ...
}:

{
  networking.firewall = {
    allowedTCPPorts = [
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    ];

    allowedUDPPorts = [
      8472 # k3s, flannel: required if using multi-node for inter-node networking
    ];
  };

  services.k3s = {
    enable = true;
    role = "server";
    # tokenFile = config.sops.secrets.k3s-token.path;
    serverAddr = "https://10.10.100.210:6443";
    clusterInit = true;
    extraFlags = toString [
      "--write-kubeconfig-mode=644"
      "--cluster-cidr=172.16.0.0/16"
      "--service-cidr=172.17.0.0/16"
      "--cluster-dns=172.17.0.10"
      # "--bind-address=0.0.0.0"
      "--cluster-domain=cluster.local"
      # "--node-ip=10.10.100.147"
      # "--rootless" # Run k3s as a non-root user
      # "--kubelet-arg=v=4" # Optionally add additional args to k3s
    ];
  };
  environment.systemPackages = [ pkgs.k3s ];
}
