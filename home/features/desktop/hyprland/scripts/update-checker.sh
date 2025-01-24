#!/usr/bin/env bash
# Function to display help message
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --flake <path>       Specify the path to the flake (must contain flake.nix)"
  echo "  --host <hostname>    Specify the nixosConfiguration name (defaults to \$HOSTNAME or output of hostname command)"
  echo "  --help               Show this help message and exit"
  echo ""
  echo "If no --flake is provided, the \$FLAKE environment variable will be used."
  echo "If no --host is provided, the \$HOSTNAME environment variable will be used."
}

# Parse command line arguments
flake_path="$HOME/nixos-config"
nixos_config_name="$HOSTNAME"
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
  echo "{ \"text\":\"\", \"alt\":\"error\", \"tooltip\":\"Invalid flake path\" }"
  exit 1
fi

# If nixos_config_name was not provided via command line, fallback to $HOSTNAME environment variable
if [ -z "$nixos_config_name" ]; then
  nixos_config_name="$HOSTNAME"
fi

# If nixos_config_name is still empty, use the output of the hostname command
if [ -z "$nixos_config_name" ]; then
  nixos_config_name=$(hostname)
fi

# Check if nixos_config_name is set, if not exit with an error
if [ -z "$nixos_config_name" ]; then
  echo "Error: No host configuration name provided. Use --host or set \$HOSTNAME."
  echo "{ \"text\":\"\", \"alt\":\"error\", \"tooltip\":\"Missing host configuration name\" }"
  exit 1
fi

# Run the updates check
if ! cd "$flake_path"; then
  echo "Error: Could not change to flake directory."
  echo "{ \"text\":\"\", \"alt\":\"error\", \"tooltip\":\"Flake directory not accessible\" }"
  exit 1
fi

# Attempt to update and build; check if 'result' exists afterward
if nix flake update nixpkgs && nix build .#nixosConfigurations.$nixos_config_name.config.system.build.toplevel; then
  if [ ! -e "./result" ]; then
    echo "Error: Build completed, but result path does not exist."
    echo "{ \"text\":\"\", \"alt\":\"error\", \"tooltip\":\"Build succeeded but result path missing\" }"
    exit 1
  fi

  # Get update count
  update_count=$(nvd diff /run/current-system ./result | grep -e '\[U' | wc -l)

  # Check if update_count is a valid integer
  if ! [[ "$update_count" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to calculate update count."
    echo "{ \"text\":\"\", \"alt\":\"error\", \"tooltip\":\"Update count calculation failed\" }"
    exit 1
  fi

else
  echo "Error: Flake update or build failed."
  echo "{ \"text\":\"\", \"alt\":\"error\", \"tooltip\":\"Flake update or build process failed\" }"
  exit 1
fi

# Set alt text based on the number of updates
status_text="has-updates"
if [ "$update_count" -eq 0 ]; then
  status_text="updated"
fi

# Set tooltip based on the presence of updates
tooltip_message="System updated"
if [ "$update_count" -gt 0 ]; then
  tooltip_message=$(nvd diff /run/current-system ./result | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS="\\n" )
fi

# Output the result as JSON
echo "{ \"text\":\"$update_count\", \"alt\":\"$status_text\", \"tooltip\":\"$tooltip_message\" }"
