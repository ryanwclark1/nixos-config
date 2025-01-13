{
  pkgs,
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
          userName = "ryanc@accentservices.com";


          passwordCommand = "${pass} ${smtp.host}/${address}";

          imap.host = "mail.m7.rs";
          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "both";
          };
          folders = {
            inbox = "Inbox";
            drafts = "Drafts";
            sent = "Sent";
            trash = "Trash";
          };
          neomutt = {
            enable = true;
            extraMailboxes = [
              "Archive"
              "Drafts"
              "Junk"
              "Sent"
              "Trash"
            ];
          };


          smtp.host = "mail.m7.rs";
          userName = address;
        }
        // common;

      college =
        rec {
          address = "g.fontes@usp.br";
          passwordCommand = "${pass} ${smtp.host}/${address}";

          msmtp.enable = true;
          smtp.host = "smtp.gmail.com";
          userName = address;
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
    Service = let
      gpgCmds = import ../cli/gpg-commands.nix {inherit pkgs;};
    in {
      Type = "oneshot";
      ExecCondition = ''
        /bin/sh -c "${gpgCmds.isUnlocked}"
      '';
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