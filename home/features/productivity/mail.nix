{
  lib,
  config,
  pkgs,
  ...
}:
let
  mbsync = "${config.programs.mbsync.package}/bin/mbsync";
  pass = "${config.programs.password-store.package}/bin/pass";
in
{
  nixpkgs.overlays = [
    (_: super: { isync = super.isync.override { withCyrusSaslXoauth2 = true; }; })
  ];

  home.packages = with pkgs; [
    oama
  ];

  accounts.email.accounts.accent = {
    enable = true;
    primary = true;
    flavor = "outlook.office365.com";
    address = "ryanc@accentvoice.com";
    userName = "ryanc@accentvoice.com";
    realName = "Ryan Clark";
    signature = {
      delimiter = "----";
      text = ''
      Ryan Clark
      ryanc@accentvoice.com
      Accent Voice
      www.accentvoice.com
    '';
    };
    # folders = {
    #   inbox = "Inbox";
    #   drafts = "Drafts";
    #   sent = "Sent";
    #   trash = "Trash";
    # };
    # Use oama with Thunderbird micrsoft client id
    passwordCommand = "${pkgs.oama}/bin/oama access ryanc@accentvoice.com";
    # smtp = {
    #   host = "smtp-mail.outlook.com";
    #   port = 587;
    #   tls = {
    #     enable = true;
    #     useStartTls = true;
    #   };
    # };

    # imap = {
    #   host = "outlook.office365.com";
    #   port = 993;
    #   tls.enable = true;
    # };

    # neomutt is the default email client in NixOS
    neomutt = {
      enable = true;
      # settings = {};
    };

    msmtp = {
      enable = true;
      extraConfig = {

      };
    };

    mbsync = {
      enable = true;
      create = "both";
      # expunge = "both";
      extraConfig.account = {
        AuthMechs = "XOAUTH2";
      };

      patterns = [ "*" ];
      # extraConfig = {};
    };

    imapnotify = {
      enable = true;
      # settings = {};
    };

    # himalaya = {
      # enable = true;
      # settings = {};
    # };

    gpg = {
      key = "4BB841BD1D5E3903";
      signByDefault = true;
      encryptByDefault = false;
    };
  };

  # mbsync = {
  #   enable = true;
  #   extraConfig.account = {
  #     AuthMechs = "LOGIN";
  #   };
  # };
  # msmtp = {
  #   enable = true;
  #   extraConfig = {
  #     auth = "login";
  #   };
  # };

  # programs.mbsync.enable = true;
  programs.msmtp.enable = true;

  # systemd.user.services.mbsync = {
  #   Unit = {
  #     Description = "mbsync synchronization";
  #   };
  #   Service =  {
  #     Type = "oneshot";
  #     ExecStart = "${mbsync} -a";
  #   };
  # };
  # systemd.user.timers.mbsync = {
  #   Unit = {
  #     Description = "Automatic mbsync synchronization";
  #   };
  #   Timer = {
  #     OnBootSec = "30";
  #     OnUnitActiveSec = "5m";
  #   };
  #   Install = {
  #     WantedBy = ["timers.target"];
  #   };
  # };

  # Run 'createMaildir' after 'linkGeneration'
  # home.activation = let
  #   mbsyncAccounts = lib.filter (a: a.mbsync.enable) (lib.attrValues config.accounts.email.accounts);
  # in lib.mkIf (mbsyncAccounts != [ ]) {
  #   createMaildir = lib.mkForce (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
  #     run mkdir -m700 -p $VERBOSE_ARG ${
  #       lib.concatMapStringsSep " " (a: a.maildir.absPath) mbsyncAccounts
  #     }
  #   '');
  # };
}
