#!/usr/bin/env bash

# Directory containing .nix files
directory="$1"

# Check if the directory is specified and exists
if [[ -z "$directory" ]]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

if [[ ! -d "$directory" ]]; then
    echo "Error: Directory '$directory' does not exist."
    exit 1
fi

# Content to prepend
prepend_content=$(cat <<'EOF'
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/rofi/style/shared/confirm.rasi" = {
    text = '''
EOF
)

# Content to append
append_content=$(cat <<'EOF'
''';
    executable = false;
  };
}
EOF
)

# Loop through all .nix files in the directory
for file in "$directory"/*.nix; do
    # Check if there are any .nix files
    if [[ ! -e "$file" ]]; then
        echo "No .nix files found in '$directory'."
        exit 0
    fi

    # Add content to the beginning and end of the file
    echo "Processing: $file"
    { echo "$prepend_content"; cat "$file"; echo "$append_content"; } > "${file}.tmp" && mv "${file}.tmp" "$file"
done

echo "Content added to all .nix files in '$directory'."
