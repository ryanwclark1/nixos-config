{
  inputs,
  ...
}:

{
  import = inputs.vscode-server.nixosModules.default
  services = {
    vscode-server = {
      enable = true;
    };
    # xserver.videoDrivers = [ "amdgpu" ];
    # Allows for copy/paste between host and guest.
    spice-vdagentd.enable = true;
    xserver.videoDrivers = [ "amdgpu" ];
  };
}
