{
  ...
}:
{
  nix = {
    sshServe = {
      enable = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+GFRs3psesCwnY5kLAmtRKRbUXrTUcOUNsdaCTuLyW nix-ssh"
      ];
      protocol = "ssh";
      write = true;
    };
    settings.trusted-users = [ "nix-ssh" ];
  };
}
