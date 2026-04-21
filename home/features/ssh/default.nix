{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Common host configuration shared across multiple hosts
  commonHostConfig = {
    user = "administrator";
    identityFile = "~/.ssh/ssh_host_ed25519_key";
    identitiesOnly = true;
    extraOptions = {
      PreferredAuthentications = "publickey";
    };
  };
in
{
  # User-level SSH client configuration
  # This complements the system-level SSH config in hosts/common/global/security/openssh.nix
  # System config handles: knownHosts (public keys)
  # User config handles: connection behavior, ControlMaster, per-user preferences
  #
  # IMPORTANT: ~/.ssh/config is fully managed by Nix through this configuration.
  # DO NOT manually edit ~/.ssh/config - it will be overwritten on rebuild.
  # To add new hosts, add entries to the matchBlocks section below, then rebuild.
  #
  # IDE TOOLS (VSCode, Cursor, etc.):
  # These tools can write to ~/.ssh/config.local, which is automatically included.
  # The main ~/.ssh/config remains managed by Nix, while IDE tools can add their
  # own entries to config.local without conflicts.
  programs.ssh = {
    enable = true;
    # Disable default config to avoid deprecation warning
    # We explicitly set the defaults we want in matchBlocks."*"
    enableDefaultConfig = false;

    matchBlocks = {
      # Default settings for all hosts (replaces enableDefaultConfig defaults)
      "*" = {
        # Key management
        addKeysToAgent = "confirm";
        identitiesOnly = false;
        hashKnownHosts = false;

        # Connection optimization
        compression = true;

        # Security: agent and X11 forwarding disabled by default
        forwardAgent = false;
        forwardX11 = false;
        forwardX11Trusted = false;

        # Additional options that aren't directly supported in matchBlocks
        extraOptions = {
          # ControlMaster: connection multiplexing for faster subsequent connections
          # Note: kssh (Kitty's SSH wrapper) may override these with its own control socket
          ControlMaster = "auto";
          ControlPath = "~/.ssh/control-%r@%h:%p";
          ControlPersist = "10m";

          # Keep connections alive
          ServerAliveInterval = "60";
          ServerAliveCountMax = "5";
          TCPKeepAlive = "yes";

          # Connection settings
          ConnectTimeout = "10";
          BatchMode = "no";

          # Security settings
          ObscureKeystrokeTiming = "no";
          StrictHostKeyChecking = "ask";
          UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts2";
        };
      };

      # ============================================
      # Host configurations
      # ============================================
      # To add a new host:
      # 1. Add a new entry in matchBlocks with the host alias as the key
      # 2. Use commonHostConfig for standard settings, or define custom config
      # 3. Rebuild with: home-manager switch
      #
      # Example for a new host:
      #   "myhost" = commonHostConfig // {
      #     hostname = "myhost.example.com";
      #     port = 2222;  # Optional: custom port
      #   };
      #
      # For hosts with different settings:
      #   "customhost" = {
      #     user = "differentuser";
      #     hostname = "customhost.example.com";
      #     identityFile = "~/.ssh/custom_key";
      #     extraOptions = {
      #       PreferredAuthentications = "publickey,password";
      #     };
      #   };
      # ============================================

      "woody" = commonHostConfig // {
        hostname = "woody";
      };

      "frametop" = commonHostConfig // {
        hostname = "frametop";
      };

      # Direct IP connections
      "10.10.100.56" = commonHostConfig // {
        hostname = "10.10.100.56";
      };

      "155.138.220.196" = commonHostConfig // {
        hostname = "155.138.220.196";
      };

      "10.10.100.129" = commonHostConfig // {
        hostname = "10.10.100.129";
      };
    };

    # Additional SSH config that will be appended to the generated config
    # Use this for any SSH options that aren't easily expressible in matchBlocks
    extraConfig = ''
      # Include IDE-managed config (VSCode, Cursor, etc. can write here)
      # SSH will silently ignore this if the file doesn't exist
      Include ~/.ssh/config.local
    '';
  };

  # Ensure ~/.ssh/config.local exists for IDE tools (VSCode, Cursor, etc.)
  # This file is writable by IDE tools and is automatically included in the SSH config
  # The file is created with proper permissions if it doesn't exist
  home.activation.ensureSshConfigLocal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SSH_CONFIG_LOCAL="${config.home.homeDirectory}/.ssh/config.local"
    if [ ! -f "$SSH_CONFIG_LOCAL" ]; then
      touch "$SSH_CONFIG_LOCAL"
      chmod 600 "$SSH_CONFIG_LOCAL"
      echo "# IDE-managed SSH configuration" > "$SSH_CONFIG_LOCAL"
      echo "# This file is automatically included by ~/.ssh/config" >> "$SSH_CONFIG_LOCAL"
      echo "# VSCode, Cursor, and other IDE tools can safely write to this file" >> "$SSH_CONFIG_LOCAL"
      echo "# without conflicts with the Nix-managed main config" >> "$SSH_CONFIG_LOCAL"
    fi
  '';

  # Ensure ~/.ssh/config is fully managed by Nix
  # This removes any manual ~/.ssh/config file and ensures Nix has full control
  # If you have existing manual entries, migrate them to matchBlocks above before rebuilding
  # home.activation.removeManualSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   if [ -f "$HOME/.ssh/config" ] && ! [ -L "$HOME/.ssh/config" ]; then
  #     # Check if the file is managed by home-manager (contains "Home Manager" comment)
  #     if ! grep -q "Home Manager" "$HOME/.ssh/config" 2>/dev/null; then
  #       echo "Warning: Found manual ~/.ssh/config file that is not managed by Nix."
  #       echo "Backing it up to ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)"
  #       cp "$HOME/.ssh/config" "$HOME/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)"
  #       echo "Please migrate any needed entries to home/features/ssh/default.nix"
  #     fi
  #   fi
  # '';

  # Helper script to clean up stale SSH control sockets
  home.file."${config.home.homeDirectory}/.local/bin/ssh-cleanup" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Clean up stale SSH control sockets
      set -uo pipefail

      readonly USER_ID=$(id -u)
      readonly RUNTIME_DIR="/run/user/$USER_ID"
      readonly SSH_DIR="${config.home.homeDirectory}/.ssh"
      readonly SOCKET_AGE_DAYS=1

      cleanup_socket() {
        local socket="$1"
        local socket_type="$2"

        [ ! -e "$socket" ] && return 0

        # Remove sockets older than specified days
        if find "$socket" -mtime +$SOCKET_AGE_DAYS >/dev/null 2>&1; then
          rm -f "$socket"
          echo "Removed old $socket_type socket: $socket"
          return 0
        fi

        # For newer sockets, try to validate they're still active
        # Extract hostname from standard SSH control socket format: control-<user>@<host>:<port>
        if [[ "$socket" =~ control-([^@]+)@([^:]+):([0-9]+) ]]; then
          local hostname="''${BASH_REMATCH[2]}"
          # Check if the control master connection is still alive
          # Using the extracted hostname for validation
          if ! timeout 1 ssh -O check -S "$socket" "$hostname" >/dev/null 2>&1; then
            rm -f "$socket"
            echo "Removed stale $socket_type socket: $socket"
          fi
        fi
        # For kssh sockets or other formats without extractable hostname,
        # we rely on age-based cleanup only (handled above)
      }

      # Clean up Kitty SSH control sockets (kssh)
      if [ -d "$RUNTIME_DIR" ]; then
        find "$RUNTIME_DIR" -name "kssh-*" -type s 2>/dev/null | while IFS= read -r socket; do
          [ -n "$socket" ] && cleanup_socket "$socket" "kssh" || true
        done
      fi

      # Clean up standard SSH control sockets
      if [ -d "$SSH_DIR" ]; then
        find "$SSH_DIR" -name "control-*" -type s 2>/dev/null | while IFS= read -r socket; do
          [ -n "$socket" ] && cleanup_socket "$socket" "SSH" || true
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
      RandomizedDelaySec = "1h";
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
      # Suppress output unless there are errors
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
