{
  config,
  pkgs,
  lib,
  ...
}:

{
  # User-level SSH client configuration
  # This complements the system-level SSH config in hosts/common/global/security/openssh.nix
  # System config handles: knownHosts (public keys)
  # User config handles: connection behavior, ControlMaster, per-user preferences
  programs.ssh = {
    enable = true;
    # Disable default config to avoid deprecation warning
    # We explicitly set the defaults we want in matchBlocks."*"
    enableDefaultConfig = false;

    # Global SSH client configuration
    # These settings apply to ~/.ssh/config (user-specific)
    extraConfig = ''
      # ControlMaster settings for connection multiplexing
      # This allows reusing SSH connections for faster subsequent connections
      ControlMaster auto
      ControlPath ~/.ssh/control-%r@%h:%p
      # Keep master connection alive for 10 minutes after last use
      ControlPersist 10m

      # Server alive settings to keep connections alive
      ServerAliveInterval 60
      ServerAliveCountMax 5
      TCPKeepAlive yes

      # Connection settings
      ConnectTimeout 10
      BatchMode no

      # Security settings
      StrictHostKeyChecking ask
      UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts2

      # Compression for slow connections
      Compression yes

      # Forward agent (be careful with this)
      ForwardAgent no

      # X11 forwarding (disabled by default, enable per-host if needed)
      ForwardX11 no
      ForwardX11Trusted no
    '';

    # Per-host configurations can be added here
    matchBlocks = {
      # Default settings for all hosts (replaces enableDefaultConfig defaults)
      "*" = {
        # Default behavior: don't automatically add keys to agent
        addKeysToAgent = "no";
        # Default behavior: only use identities explicitly specified
        identitiesOnly = false;
        # Default behavior: don't hash known hosts (we manage them explicitly)
        hashKnownHosts = false;
      };

      # Woody host configuration
      "woody" = {
        hostname = "woody";
        user = "administrator";
        identityFile = "~/.ssh/ssh_host_ed25519_key";
      };

      # Frametop host configuration
      "frametop" = {
        hostname = "frametop";
        user = "administrator";
        identityFile = "~/.ssh/ssh_host_ed25519_key";
      };
    };
  };

  # Create a helper script to clean up stale SSH control sockets
  home.file."${config.home.homeDirectory}/.local/bin/ssh-cleanup" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Clean up stale SSH control sockets

      # Clean up Kitty SSH control sockets
      if [ -d "/run/user/$(id -u)" ]; then
        find /run/user/$(id -u) -name "kssh-*" -type s -mtime +1 -delete 2>/dev/null
        echo "Cleaned up stale Kitty SSH control sockets"
      fi

      # Clean up standard SSH control sockets
      if [ -d "${config.home.homeDirectory}/.ssh" ]; then
        find "${config.home.homeDirectory}/.ssh" -name "control-*" -type s -mtime +1 -delete 2>/dev/null
        echo "Cleaned up stale SSH control sockets"
      fi

      # Also clean up sockets that are not responding
      if [ -d "${config.home.homeDirectory}/.ssh" ]; then
        for socket in "${config.home.homeDirectory}/.ssh"/control-*; do
          if [ -S "$socket" ]; then
            # Try to check if the socket is still valid
            if ! timeout 1 ssh -O check -S "$socket" dummy 2>/dev/null; then
              rm -f "$socket"
              echo "Removed stale socket: $socket"
            fi
          fi
        done
      fi
    '';
  };

  # Systemd timer to automatically clean up stale sockets daily
  systemd.user.timers.ssh-cleanup = {
    Unit = {
      Description = "Clean up stale SSH control sockets";
    };
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.ssh-cleanup = {
    Unit = {
      Description = "Clean up stale SSH control sockets";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/ssh-cleanup";
    };
  };
}

