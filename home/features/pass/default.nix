{
  pkgs,
  config,
  ...
}:

{
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
    package = pkgs.pass.withExtensions (p: [p.pass-otp]);
  };

  services.pass-secret-service = {
    enable = true;
    storePath = "${config.home.homeDirectory}/.password-store";
    extraArgs = ["-e${config.programs.password-store.package}/bin/pass"];
  };

  # home.persistence = {
  #   "/persist/${config.home.homeDirectory}".directories = [".password-store"];
  # };
}