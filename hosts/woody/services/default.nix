{
  ...
}:

{
  imports = [
    ./spice.nix
    ./vscode-server.nix
  ];

  services = {
    xserver.videoDrivers = [ "amdgpu" ];
  };
}
