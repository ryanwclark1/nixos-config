{
  config,
  lib,
  pkgs,
  ...
}:

{

  accounts = {
    email = {
      maildirBasePath = "Mail";
      accounts = {
        "accent" =
          let
            accent_email = "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."accent-email/accent-email-address".path})";
          in
          {
          address = accent_email;
          flavor = "gmail.com";
          # name = config.sops.secrets.accent-email-name.path;
          realName = "Ryan Clark";
          # userName = config.sops.secrets."accent-email/accent-email-username".path;
          # username = "ryanc@accentservices.com";
          passwordCommand = ''${pkgs.coreutils}/bin/cat ${config.sops.secrets."accent-email/accent-email-password".path}'';
          primary = true;
          # imap = {
            # host = builtins.readFile config.sops.secrets."accent-email/accent-email-imap-host".path;
            # port = 993;
            # port = builtins.readFile config.sops.secrets."accent-email/accent-email-imap-port".path;
          # };
          # smtp = {
          #   host = config.sops.secrets."accent-email/accent-email-smtp-host".path;
          #   port = 465;
          # };
          neomutt = {
            enable = true;
            mailboxType = "imap";
            showDefaultMailbox = true;
          };
        };
      };
    };
  };
  programs.neomutt = {
    enable = true;
    package = pkgs.neomutt;
    editor = "$EDITOR";
    vimKeys = true;
  };

  home.file = {
    ".config/accent-email" = {
      text =
        ''
          password = ''$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."accent-email/accent-email-password".path}')'
          username = ${config.sops.secrets."accent-email/accent-email-username".key}
      '';
    };
  };
}