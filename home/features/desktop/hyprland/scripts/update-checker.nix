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
  flake_path=""
  nixos_config_name=""
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --flake) flake_path="$2"; shift ;;
      --host) nixos_config_name="$2"; shift ;;
      --help) show_help; exit 0 ;;
      *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
  done

  # If flake_path was not provided via command line, fallback to $FLAKE environment variable
  if [ -z "$flake_path" ]; then
    flake_path="$FLAKE"
  fi

  # Check if the flake path is valid and flake.nix exists
  if [ -z "$flake_path" ] || [ ! -f "$flake_path/flake.nix" ]; then
    echo "Error: Invalid or missing flake path. Provide a valid flake location containing flake.nix."
    exit 1
  fi

  # If nixos_config_name was not provided via command line, fallback to $HOST environment variable
  if [ -z "$nixos_config_name" ]; then
    nixos_config_name="$HOSTNAME"
  fi

  # If nixos_config_name was not provided via command line, use the output of the hostname command
  if [ -z "$nixos_config_name" ]; then
    nixos_config_name=$(hostname)
  fi

  # Check if nixos_config_name is set, if not exit with an error
  if [ -z "$nixos_config_name" ]; then
    echo "Error: No host configuration name provided. Use --host or set \$HOSTNAME."
    exit 1
  fi

  # Run the updates check
  update_count="$(cd "$flake_path" && nix flake update nixpkgs && nix build .#nixosConfigurations.$nixos_config_name.config.system.build.toplevel && nvd diff /run/current-system ./result | grep -e '\[U' | wc -l)"

  # Set alt text based on the number of updates
  status_text="has-updates"
  if [ "$update_count" -eq 0 ]; then
    status_text="updated"
  fi

  # Set tooltip based on the presence of updates
  tooltip_message="System updated"
  if [ "$update_count" != 0 ]; then
    tooltip_message=$(cd "$flake_path" && nvd diff /run/current-system ./result | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS="\\n" )
  fi

  # Output the result as JSON
  echo "{ \"text\":\"$update_count\", \"alt\":\"$status_text\", \"tooltip\":\"$tooltip_message\" }"

''