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

        # Compression for slow connections
        compression = true;

        # Forward agent (be careful with this)
        forwardAgent = false;

        # X11 forwarding (disabled by default, enable per-host if needed)
        forwardX11 = false;
        forwardX11Trusted = false;

        # Additional options that aren't directly supported in matchBlocks
        # These are SSH config options that need to be specified as raw key-value pairs
        extraOptions = {
          # ControlMaster settings for connection multiplexing
          # This allows reusing SSH connections for faster subsequent connections
          # Note: kssh (Kitty's SSH wrapper) may override these with its own control socket
          ControlMaster = "auto";
          ControlPath = "~/.ssh/control-%r@%h:%p";
          # Keep master connection alive for 10 minutes after last use
          ControlPersist = "10m";

          # Server alive settings to keep connections alive
          ServerAliveInterval = "60";
          ServerAliveCountMax = "5";
          TCPKeepAlive = "yes";

          # Connection settings
          ConnectTimeout = "10";
          BatchMode = "no";

          # Security settings
          StrictHostKeyChecking = "ask";
          UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts2";
        };
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

      # Direct IP connection (10.10.100.129)
      # Use: ssh 10.10.100.129
      "10.10.100.129" = {
        hostname = "10.10.100.129";
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

      USER_ID=$(id -u)
      RUNTIME_DIR="/run/user/$USER_ID"

      # Clean up Kitty SSH control sockets (kssh)
      if [ -d "$RUNTIME_DIR" ]; then
        # Find and remove stale kssh sockets (older than 1 day or not responding)
        find "$RUNTIME_DIR" -name "kssh-*" -type s 2>/dev/null | while read -r socket; do
          # Check if socket is older than 1 day
          if [ -n "$(find "$socket" -mtime +1 2>/dev/null)" ]; then
            rm -f "$socket"
            echo "Removed old kssh socket: $socket"
          # Or check if socket is not responding
          elif ! timeout 1 ssh -O check -S "$socket" dummy 2>/dev/null; then
            rm -f "$socket"
            echo "Removed stale kssh socket: $socket"
          fi
        done
      fi

      # Clean up standard SSH control sockets
      if [ -d "${config.home.homeDirectory}/.ssh" ]; then
        # Remove sockets older than 1 day
        find "${config.home.homeDirectory}/.ssh" -name "control-*" -type s -mtime +1 -delete 2>/dev/null

        # Also clean up sockets that are not responding
        for socket in "${config.home.homeDirectory}/.ssh"/control-*; do
          if [ -S "$socket" ] 2>/dev/null; then
            # Try to check if the socket is still valid
            if ! timeout 1 ssh -O check -S "$socket" dummy 2>/dev/null; then
              rm -f "$socket"
              echo "Removed stale SSH socket: $socket"
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

