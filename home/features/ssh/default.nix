{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Common host configuration shared across multiple hosts
  commonHostConfig = {
    User = "administrator";
    IdentityFile = "~/.ssh/ssh_host_ed25519_key";
    IdentitiesOnly = "yes";
    PreferredAuthentications = "publickey";
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
  # To add new hosts, add entries to the settings section below, then rebuild.
  #
  # IDE TOOLS (VSCode, Cursor, etc.):
  # These tools can write to ~/.ssh/config.local, which is automatically included.
  # The main ~/.ssh/config remains managed by Nix, while IDE tools can add their
  # own entries to config.local without conflicts.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = lib.mkForce false;

    settings = {
      # Default settings for all hosts
      "*" = {
        # Key management
        AddKeysToAgent = "confirm";
        IdentitiesOnly = "no";
        HashKnownHosts = "no";

        # Connection optimization
        Compression = "yes";

        # Security: agent and X11 forwarding disabled by default
        ForwardAgent = "no";
        ForwardX11 = "no";
        ForwardX11Trusted = "no";

        # ControlMaster: connection multiplexing for faster subsequent connections
        # Note: kssh (Kitty's SSH wrapper) may override these with its own control socket
        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%r@%h:%p";
        ControlPersist = "10m";

        # Keep connections alive
        ServerAliveInterval = 60;
        ServerAliveCountMax = 5;
        TCPKeepAlive = "yes";

        # Connection settings
        ConnectTimeout = 10;
        BatchMode = "no";
        SendEnv = [
          "COLORTERM"
          "TERM_PROGRAM"
          "TERM_PROGRAM_VERSION"
        ];

        # Security settings
        ObscureKeystrokeTiming = "no";
        StrictHostKeyChecking = "ask";
      };

      # ============================================
      # Host configurations
      # ============================================
      # To add a new host:
      # 1. Add a new entry in settings with the host alias as the key
      # 2. Use commonHostConfig for standard settings, or define custom config
      # 3. Rebuild with: home-manager switch
      #
      # Example for a new host:
      #   "myhost" = commonHostConfig // {
      #     HostName = "myhost.example.com";
      #     Port = 2222;  # Optional: custom port
      #   };
      #
      # For hosts with different settings:
      #   "customhost" = {
      #     User = "differentuser";
      #     HostName = "customhost.example.com";
      #     IdentityFile = "~/.ssh/custom_key";
      #     PreferredAuthentications = "publickey,password";
      #   };
      # ============================================

      "woody" = commonHostConfig // {
        HostName = "woody";
      };

      "frametop" = commonHostConfig // {
        HostName = "frametop";
      };

      # Direct IP connections
      "10.10.100.56" = commonHostConfig // {
        HostName = "10.10.100.56";
      };

      "155.138.220.196" = commonHostConfig // {
        HostName = "155.138.220.196";
      };

      "10.10.100.129" = commonHostConfig // {
        HostName = "10.10.100.129";
      };
    };

  };

  # Redirect the Nix-managed SSH config to a different file
  # This allows the main ~/.ssh/config to be a standard, writable file
  home.file.".ssh/config".target = lib.mkForce ".ssh/config_nix";

  # Ensure ~/.ssh/config exists, is writable, and includes managed/local config fragments
  home.activation.ensureSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SSH_CONFIG="${config.home.homeDirectory}/.ssh/config"
    NIX_SSH_CONFIG="${config.home.homeDirectory}/.ssh/config_nix"
    LOCAL_SSH_CONFIG="${config.home.homeDirectory}/.ssh/config.local"

    # If the main config is a symlink (from previous home-manager generations), remove it
    if [ -L "$SSH_CONFIG" ]; then
      rm "$SSH_CONFIG"
    fi

    # Create the file if it doesn't exist
    if [ ! -f "$SSH_CONFIG" ]; then
      touch "$SSH_CONFIG"
      chmod 600 "$SSH_CONFIG"
      echo "# Writable SSH configuration file" > "$SSH_CONFIG"
      echo "# Programs can write to this file directly." >> "$SSH_CONFIG"
      echo "Include ~/.ssh/config.local" >> "$SSH_CONFIG"
      echo "Include ~/.ssh/config_nix" >> "$SSH_CONFIG"
      echo "" >> "$SSH_CONFIG"
    else
      # Merge required includes into the writable config once. Local entries come
      # first so tools can override generated host blocks when they need to.
      TMP_CONF=$(mktemp)
      {
        echo "Include ~/.ssh/config.local"
        echo "Include ~/.ssh/config_nix"
        grep -v -E '^[[:space:]]*Include[[:space:]]+~/.ssh/config[.]local[[:space:]]*$|^[[:space:]]*Include[[:space:]]+~/.ssh/config_nix[[:space:]]*$' "$SSH_CONFIG" 2>/dev/null || true
      } > "$TMP_CONF"
      cat "$TMP_CONF" > "$SSH_CONFIG"
      rm "$TMP_CONF"
      chmod 600 "$SSH_CONFIG"
    fi

    if [ ! -f "$LOCAL_SSH_CONFIG" ]; then
      touch "$LOCAL_SSH_CONFIG"
      chmod 600 "$LOCAL_SSH_CONFIG"
      echo "# Local SSH configuration file" > "$LOCAL_SSH_CONFIG"
      echo "# Programs can write host entries here without touching the Nix-managed config." >> "$LOCAL_SSH_CONFIG"
      echo "" >> "$LOCAL_SSH_CONFIG"
    fi
  '';

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
