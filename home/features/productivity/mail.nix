{
  lib,
  config,
  ...
}: let
  mbsync = "${config.programs.mbsync.package}/bin/mbsync";
  pass = "${config.programs.password-store.package}/bin/pass";

  common = rec {
    realName = "Ryan Clark";
    signature = {
      showSignature = "append";
      text = ''
        ${realName}

      '';
    };
  };
in {
  # home.persistence = {
  #   "/persist/${config.home.homeDirectory}".directories = ["Mail"];
  # };

  accounts.email = {
    maildirBasePath = "Mail";
    accounts = {
      personal =
        rec {
          primary = true;
          address = "ryanc@accentservices.com";
          flavor = "gmail.com";
          realName = "Ryan Clark";
          userName = address;
          # userName = config.sops.secrets."accent-email/accent-email-username".path;
          # passwordCommand = ''
          #   ${pkgs.coreutils}/bin/cat ${config.sops.secrets."accent-email/accent-email-password".path}
          # '';
          smtp = {
            host = "smtp.gmail.com";
            port = 465;
          };
          imap = {
            host = "imap.gmail.com";
            port = 993;
          };
          passwordCommand = "${pass} ${smtp.host}/${address}";
          neomutt = {
            enable = true;
            mailboxType = "imap";
            showDefaultMailbox = true;
            extraMailboxes = [
              "Archive"
              "Drafts"
              "Junk"
              "Sent"
              "Trash"
            ];
          };
          msmtp.enable = true;
        }
        // common;
    };
  };

  programs.mbsync.enable = true;
  programs.msmtp.enable = true;

  systemd.user.services.mbsync = {
    Unit = {
      Description = "mbsync synchronization";
    };
    Service =  {
      Type = "oneshot";
      ExecStart = "${mbsync} -a";
    };
  };
  systemd.user.timers.mbsync = {
    Unit = {
      Description = "Automatic mbsync synchronization";
    };
    Timer = {
      OnBootSec = "30";
      OnUnitActiveSec = "5m";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };

  # Run 'createMaildir' after 'linkGeneration'
  home.activation = let
    mbsyncAccounts = lib.filter (a: a.mbsync.enable) (lib.attrValues config.accounts.email.accounts);
  in lib.mkIf (mbsyncAccounts != [ ]) {
    createMaildir = lib.mkForce (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run mkdir -m700 -p $VERBOSE_ARG ${
        lib.concatMapStringsSep " " (a: a.maildir.absPath) mbsyncAccounts
      }
    '');
  };
}