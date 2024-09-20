{
  pkgs
}:

pkgs.writeShellScriptBin "update-checker" ''
  # Function to display help message
  show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --flake <path>       Specify the path to the flake (must contain flake.nix)"
    echo "  --host <hostname>    Specify the nixosConfiguration name (defaults to \$HOST)"
    echo "  --help               Show this help message and exit"
    echo ""
    echo "If no --flake is provided, the \$FLAKE environment variable will be used."
    echo "If no --host is provided, the \$HOST environment variable will be used."
  }

  # Parse command line arguments
  FLAKE=""
  HOST=""
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --flake) FLAKE="$2"; shift ;;
      --host) HOST="$2"; shift ;;
      --help) show_help; exit 0 ;;
      *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
  done

  # If FLAKE was not provided via command line, fallback to $FLAKE environment variable
  if [ -z "$FLAKE" ]; then
    FLAKE="$FLAKE"
  fi

  # Check if the flake path is valid and flake.nix exists
  if [ -z "$FLAKE" ] || [ ! -f "$FLAKE/flake.nix" ]; then
    echo "Error: Invalid or missing flake path. Provide a valid flake location containing flake.nix."
    exit 1
  fi

  # If HOST was not provided via command line, fallback to $HOST environment variable
  if [ -z "$HOST" ]; then
    HOST="$HOST"
  fi

  # Check if HOST is set, if not exit with an error
  if [ -z "$HOST" ]; then
    echo "Error: No host configuration name provided. Use --host or set \$HOST."
    exit 1
  fi

  # Run the updates check
  updates="$(cd "$FLAKE" && nix flake lock --update-input nixpkgs && nix build .#nixosConfigurations.$HOST.config.system.build.toplevel && nvd diff /run/current-system ./result | grep -e '\[U' | wc -l)"

  # Set alt text based on the number of updates
  alt="has-updates"
  if [ "$updates" -eq 0 ]; then
    alt="updated"
  fi

  # Set tooltip based on the presence of updates
  tooltip="System updated"
  if [ "$updates" != 0 ]; then
    tooltip=$(cd "$FLAKE" && nvd diff /run/current-system ./result | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS="\\n" )
  fi

  # Output the result as JSON
  echo "{ \"text\":\"$updates\", \"alt\":\"$alt\", \"tooltip\":\"$tooltip\" }"
''