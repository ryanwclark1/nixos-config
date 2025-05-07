{
  pkgs,
  config,
  ...
}:
let
  configDir = "${config.home.homeDirectory}/.config";
  dotrepoDir = "${config.home.homeDirectory}/Code/dotfiles";
  defaultFileList = [ "starship.toml" ];
  defaultDirList = [ "atuin" "bat" "eza" "fd" "k9s" "navi" "ripgrep" "ripgrep-all" "scripts" "tealdeer" "tmux" "yazi"];
  updatedDots = pkgs.writeShellScriptBin "update-dots" ''
    set -euxo pipefail

    # ensure we own everything under dotrepoDir
    USER="$(id -un)"
    GROUP="$(id -gn)"
    echo "Updating dotfiles repository at ${dotrepoDir} as $USER:$GROUP"

    # ensure we own the repo before we start
    chown -R "$USER:$GROUP" "${dotrepoDir}" || true

    # Default file and directory lists (relative to "${configDir}")
    DEFAULT_FILE_LIST=(${toString defaultFileList})
    DEFAULT_DIR_LIST=(${toString defaultDirList})

    sync_file() {
      local src="${configDir}/$1"
      local dst="${dotrepoDir}/$1"

      # removed upstream?
      if [[ ! -e "$src" && -e "$dst" ]]; then
        rm -f "$dst"
        echo "  [removed] $1"
        return
      fi

      # new file?
      if [[ -f "$src" && ! -e "$dst" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -L "$src" "$dst"
        echo "  [added]   $1"
      # updated file?
      elif [[ -f "$src" && -f "$dst" ]]; then
        if ! cmp -s "$src" "$dst"; then
          cp -L "$src" "$dst"
          echo "  [updated] $1"
        else
          echo "  [skip]    $1 (unchanged)"
        fi
      fi

      # fix perms on anything we copied
      if [[ -e "$dst" ]]; then
        chown "''${USER}:''${GROUP}" "$dst"
        chmod u+w "$dst"
      fi
    }

    sync_dir() {
      local src="${configDir}/$1/"
      local dst="${dotrepoDir}/$1/"

      # removed upstream?
      if [[ ! -d "${configDir}/$1" && -d "${dotrepoDir}/$1" ]]; then
        rm -rf "${dotrepoDir}/$1"
        echo "  [removed] dir/$1"
        return
      fi

      # only sync if the source exists
      if [[ -d "${configDir}/$1" ]]; then
        echo "  [sync]    dir/$1"
        rsync -aL --delete --force --itemize-changes \
          "''${src}" "''${dst}" | sed 's/^/            /'
        # fix ownership
        chown -R "''${USER}:''${GROUP}" "${dotrepoDir}/$1"
        find "${dotrepoDir}/$1" -type f -exec chmod u+w {} +
      fi
    }

    # --- sync files ---
    echo "→ Files:"
    for f in "''${DEFAULT_FILE_LIST[@]}"; do
      sync_file "$f"
    done

    # --- sync directories ---
    echo "→ Directories:"
    for d in "''${DEFAULT_DIR_LIST[@]}"; do
      sync_dir "$d"
    done

    # commit & push if anything changed
    cd "${dotrepoDir}"
    if [[ -n $(git status --porcelain) ]]; then
      echo "→ Git: committing changes"
      git add .
      git commit -m "Auto-update: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      git push origin main
    else
      echo "→ No changes to commit."
    fi
  '';

  in
{
  home.packages = with pkgs; [
    git
    updatedDots
  ];

  systemd.user.services.update-dots = {
    Unit = {
      Description = "Copy and commit dot config files";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/update-dots";
      WorkingDirectory = "${config.home.homeDirectory}/Code/dotfiles";
      Environment      = "HOME=${config.home.homeDirectory}";
      StandardOutput   = "journal";
      StandardError    = "journal";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers.update-dots = {
    Unit = {
      Description = "Run Dot Files Sync every 6 hours";
    };

    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "6h";
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
