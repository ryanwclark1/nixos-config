{
  lib,
  pkgs,
  ...
}:

{
  services.chromadb = {
    enable = true;
    host = "127.0.0.1";
    openFirewall = true;
    port = 8181;
  };

  # Override the systemd service to remove unsupported --log-path argument
  systemd.services.chromadb = {
    serviceConfig = {
      ExecStart = lib.mkForce "${pkgs.python3Packages.chromadb}/bin/chroma run --path /var/lib/chromadb --host 127.0.0.1 --port 8181";
    };
  };
}
