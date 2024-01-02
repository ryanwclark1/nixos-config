# ./host/frametop/ssh.nix

{
  config,
  pkgs,
  ...
}:

{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings = {
      AllowTcpForwarding = true;
      X11Forwarding = true;
      PermitRootLogin = "no";         # disable root login
      PasswordAuthentication = true; # disable password login
    };
    openFirewall = true;
  };
}