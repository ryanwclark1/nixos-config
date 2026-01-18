{
  config,
  lib,
  ...
}:

{
  # Systemd journal configuration
  services.journald = {
    extraConfig = ''
      # Limit journal size
      SystemMaxUse=1G
      SystemKeepFree=1G
      SystemMaxFileSize=100M

      # Retention settings
      MaxRetentionSec=1month
      MaxFileSec=1week

      # Forward to syslog only if rsyslog is enabled
      # ForwardToSyslog is set conditionally below
      ForwardToKMsg=yes
      ForwardToConsole=yes
      ForwardToWall=yes

      # Compression
      Compress=yes

      # Rate limiting to prevent log spam
      RateLimitIntervalSec=30s
      RateLimitBurst=10000

      # Storage settings
      Storage=persistent
      SplitMode=uid
    ''
    + lib.optionalString config.services.rsyslogd.enable ''
      # Only forward to syslog if rsyslog is enabled
      ForwardToSyslog=yes
    '';
  };

  # Rsyslog configuration (if enabled)
  services.rsyslogd = {
    enable = lib.mkDefault false;
    defaultConfig = ''
      # Log all kernel messages
      kern.*                                                  /var/log/kern.log

      # Log anything (except mail) of level info or higher
      *.info;mail.none;authpriv.none;cron.none               /var/log/messages

      # Log authpriv messages
      authpriv.*                                              /var/log/secure

      # Log mail messages
      mail.*                                                  /var/log/maillog

      # Log cron messages
      cron.*                                                  /var/log/cron

      # Everybody gets emergency messages
      *.emerg                                                 :omusrmsg:*
    '';
  };
}
