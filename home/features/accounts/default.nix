{
  config,
  pkgs,
  ...
}:

{
  sops.secrets = {
    accent-email-address = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-username = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-name = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-realname = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-password = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-imap-host = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-imap-port = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-smtp-host = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-smtp-port = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
    accent-email-flavor = {
      sopsFile = ../../../secrets/secrets.yaml;
    };
  };
  accounts = {
    email = {
      maildirBasePath = "Mail";
      accounts = {
        "accent" = {
          address = config.sops.secrets.accent-email-address.path;
          flavor = config.sops.secrets.accent-email-flavor.path;
          name = config.sops.secrets.accent-email-name.path;
          realName = config.sops.secrets.accent-email-realname.path;
          username = config.sops.secrets.accent-email-username.path;
          # passwordCommand = "";
          imap = {
            host = config.sops.secrets.accent-email-imap-host.path;
            port = config.sops.secrets.accent-email-imap-port.path;
          };
          smtp = {
            host = config.sops.secrets.accent-email-smtp-host.path;
            port = config.sops.secrets.accent-email-smtp-port.path;
          };
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
}