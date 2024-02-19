{
  ...
}:

{
  programs = {

    tldr.enable = true;
    documentation = {
      enable = true;
      info.enable = true;
      nixos.enable = true;
      man = {
        enable = true;
        generateCaches = true;
      };
    };
  };
}
