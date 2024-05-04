# ./host/common/global/optional/nfs.nix
{
  ...
}:

{
  services.nfs.server = {
    enable = true;
    exports = ''
      /export         10.10.100.1/23(rw,fsid=0,no_subtree_check)
      /export/iso  10.10.100.1/23(rw,nohide,insecure,no_subtree_check)
    '';
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
  };
  networking.firewall = {
    enable = true;
      # for NFSv3; view with `rpcinfo -p`
    allowedTCPPorts = [ 111  2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 111 2049 4000 4001  4002 20048 ];
  };
}