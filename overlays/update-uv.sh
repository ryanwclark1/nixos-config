#!/usr/bin/env bash

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate or update a Nix overlay for a GitHub repository with Rust dependencies.

Options:
    -h, --help              Show this help message
    -v, --version VER      Specify package version (e.g., 0.5.10)
                          If not specified, latest version will be used
    -u, --user NAME       GitHub username/organization (default: astral-sh)
    -r, --repo NAME       GitHub repository name (default: uv)

Capabilities:
    - Fetches latest release version from GitHub if not specified
    - Generates Nix overlay with correct source and cargo hashes
    - Handles git dependencies in Cargo.lock automatically
    - Generates overlay file named after the repository
    - Supports any GitHub repository with Rust/Cargo projects
    - Provides proper SHA256 hashes in base64 format
    - Creates importCargoLock configuration with outputHashes

Examples:
    $(basename "$0")                            # Use latest version of astral-sh/uv
    $(basename "$0") -v 0.5.10                  # Use specific version of astral-sh/uv
    $(basename "$0") -u userName -r repoName    # Use different GitHub repository
EOF
    exit 0
}

# Parse command line arguments
VERSION=""
GITHUB_USER="astral-sh"
GITHUB_REPO="uv"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--version)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                VERSION=$2
                shift 2
            else
                echo "Error: Version argument is missing" >&2
                exit 1
            fi
            ;;
        -u|--user)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                GITHUB_USER=$2
                shift 2
            else
                echo "Error: GitHub user/organization is missing" >&2
                exit 1
            fi
            ;;
        -r|--repo)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                GITHUB_REPO=$2
                shift 2
            else
                echo "Error: Repository name is missing" >&2
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            ;;
    esac
done

# Function to get latest version from GitHub releases
get_latest_version() {
    local user=$1
    local repo=$2
    curl -s "https://api.github.com/repos/${user}/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to get hash for a git repository
get_git_hash() {
    local url=$1
    local rev=$2
    url=${url#https://}
    local hash=$(nix-prefetch-git --url "https://$url" --rev "$rev" 2>/dev/null | grep '"sha256"' | cut -d'"' -f4)
    echo "sha256-$(nix hash convert --hash-algo sha256 --to base64 $hash)"
}

# Function to extract git dependencies from Cargo.lock
parse_cargo_lock() {
    local user=$1
    local repo=$2
    local version=$3
    local temp_file=$(mktemp)
    local output_hashes=""

    curl -s "https://raw.githubusercontent.com/${user}/${repo}/${version}/Cargo.lock" > "$temp_file"

    local current_name=""
    local current_version=""

    while IFS= read -r line; do
        if [[ $line == *"name ="* ]]; then
            current_name=$(echo "$line" | cut -d'"' -f2)
        elif [[ $line == *"version ="* ]]; then
            current_version=$(echo "$line" | cut -d'"' -f2)
        elif [[ $line == *"source = \"git+"* ]]; then
            local git_url=$(echo "$line" | sed -n 's/.*git+https:\/\/\([^?]*\).*/\1/p')
            local git_rev=$(echo "$line" | sed -n 's/.*rev=\([^#"]*\).*/\1/p')

            echo "Fetching hash for ${current_name}-${current_version} from ${git_url} rev ${git_rev}..." >&2
            local dep_hash=$(get_git_hash "$git_url" "$git_rev")

            if [ -n "$output_hashes" ]; then
                output_hashes+=$'\n'
            fi
            output_hashes+="        \"${current_name}-${current_version}\" = \"${dep_hash}\";"
        fi
    done < "$temp_file"

    rm "$temp_file"
    echo "$output_hashes"
}

# Function to get hashes
get_hashes() {
    local user=$1
    local repo=$2
    local version=$3

    local src_hash=$(nix-prefetch-url --unpack "https://github.com/${user}/${repo}/archive/refs/tags/${version}.tar.gz")
    src_hash="sha256-$(nix hash convert --hash-algo sha256 --to base64 $src_hash)"

    local cargo_lock_hash=$(nix-prefetch-url "https://raw.githubusercontent.com/${user}/${repo}/${version}/Cargo.lock")
    cargo_lock_hash="sha256-$(nix hash convert --hash-algo sha256 --to base64 $cargo_lock_hash)"

    echo "${src_hash} ${cargo_lock_hash}"
}

# Function to update the overlay file
update_overlay() {
    local user=$1
    local repo=$2
    local version=$3
    local src_hash=$4
    local cargo_lock_hash=$5
    local output_hashes=$6
    local overlay_file="${repo}-overlay.nix"

    cat > "${overlay_file}" << EOF
final: prev: {
  ${repo} = prev.${repo}.overrideAttrs (_: rec {
    version = "${version}";

    src = prev.fetchFromGitHub {
      owner = "${user}";
      repo = "${repo}";
      rev = "refs/tags/\${version}";
      hash = "${src_hash}";
    };

    cargoDeps = prev.rustPlatform.importCargoLock {
      lockFile = prev.fetchurl {
        url = "https://raw.githubusercontent.com/${user}/${repo}/\${version}/Cargo.lock";
        hash = "${cargo_lock_hash}";
      };
      outputHashes = {
${output_hashes}
      };
    };
  });
}
EOF
}

# Main execution
echo "Checking repository version..." >&2
if [ -z "$VERSION" ]; then
    VERSION=$(get_latest_version "$GITHUB_USER" "$GITHUB_REPO")
    echo "Using latest version: ${VERSION}" >&2
else
    echo "Using specified version: ${VERSION}" >&2
fi

echo "Getting hashes..." >&2
read src_hash cargo_lock_hash <<< $(get_hashes "$GITHUB_USER" "$GITHUB_REPO" "$VERSION")
echo "Source hash: ${src_hash}" >&2
echo "Cargo.lock hash: ${cargo_lock_hash}" >&2

echo "Parsing Cargo.lock for git dependencies..." >&2
OUTPUT_HASHES=$(parse_cargo_lock "$GITHUB_USER" "$GITHUB_REPO" "$VERSION")
echo "Found git dependencies" >&2

echo "Updating overlay..." >&2
update_overlay "$GITHUB_USER" "$GITHUB_REPO" "$VERSION" "$src_hash" "$cargo_lock_hash" "$OUTPUT_HASHES"
echo "Overlay updated successfully as ${GITHUB_REPO}-overlay.nix!" >&2