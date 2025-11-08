#!/usr/bin/env bash
# tmux-forceline v3.0 Distribution Creator
# Creates packages for various package managers and platforms

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly VERSION="3.0.0"
readonly PACKAGE_NAME="tmux-forceline"
readonly DESCRIPTION="Revolutionary tmux status bar with native performance integration"
readonly AUTHOR="tmux-forceline contributors"
readonly LICENSE="MIT"
readonly HOMEPAGE="https://github.com/your-org/tmux-forceline"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Distribution options
CREATE_HOMEBREW="no"
CREATE_SNAP="no"
CREATE_DEB="no"
CREATE_RPM="no"
CREATE_ARCH="no"
CREATE_NIX="no"
CREATE_TARBALL="yes"
OUTPUT_DIR="${SCRIPT_DIR}/dist"

# Function: Print colored output
print_status() {
    local level="$1"
    shift
    case "$level" in
        "info")    echo -e "${BLUE}ℹ${NC} $*" ;;
        "success") echo -e "${GREEN}✅${NC} $*" ;;
        "warning") echo -e "${YELLOW}⚠${NC} $*" ;;
        "error")   echo -e "${RED}❌${NC} $*" ;;
        "header")  echo -e "${PURPLE}📦${NC} ${WHITE}$*${NC}" ;;
    esac
}

# Function: Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Distribution Creation Options:
  --homebrew         Create Homebrew formula
  --snap             Create Snap package
  --deb              Create Debian package
  --rpm              Create RPM package
  --arch             Create Arch Linux PKGBUILD
  --nix              Create Nix package
  --tarball          Create tarball distribution (default)
  --all              Create all package types
  --output=DIR       Output directory (default: ./dist)
  --help             Show this help message

Examples:
  $0                          # Create tarball only
  $0 --homebrew --snap        # Create Homebrew and Snap packages
  $0 --all                    # Create all package types
  $0 --output=/tmp/packages   # Custom output directory

EOF
}

# Function: Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --homebrew)
                CREATE_HOMEBREW="yes"
                ;;
            --snap)
                CREATE_SNAP="yes"
                ;;
            --deb)
                CREATE_DEB="yes"
                ;;
            --rpm)
                CREATE_RPM="yes"
                ;;
            --arch)
                CREATE_ARCH="yes"
                ;;
            --nix)
                CREATE_NIX="yes"
                ;;
            --tarball)
                CREATE_TARBALL="yes"
                ;;
            --all)
                CREATE_HOMEBREW="yes"
                CREATE_SNAP="yes"
                CREATE_DEB="yes"
                CREATE_RPM="yes"
                CREATE_ARCH="yes"
                CREATE_NIX="yes"
                CREATE_TARBALL="yes"
                ;;
            --output=*)
                OUTPUT_DIR="${1#*=}"
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_status "error" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Function: Setup output directory
setup_output_dir() {
    print_status "info" "Setting up output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"

    # Clean previous builds
    rm -rf "${OUTPUT_DIR:?}"/*

    print_status "success" "Output directory ready"
}

# Function: Create source tarball
create_source_tarball() {
    if [[ "$CREATE_TARBALL" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating source tarball..."

    local tarball_name="${PACKAGE_NAME}-${VERSION}.tar.gz"
    local temp_dir="/tmp/${PACKAGE_NAME}-${VERSION}"

    # Create temporary directory
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"

    # Copy source files
    cp -r "$PROJECT_DIR"/* "$temp_dir/"

    # Remove unwanted files
    find "$temp_dir" -name ".git*" -exec rm -rf {} + 2>/dev/null || true
    find "$temp_dir" -name "*.backup*" -exec rm -f {} + 2>/dev/null || true
    find "$temp_dir" -name ".DS_Store" -exec rm -f {} + 2>/dev/null || true
    rm -rf "$temp_dir/packaging/dist" 2>/dev/null || true

    # Create tarball
    (cd "$(dirname "$temp_dir")" && tar -czf "$OUTPUT_DIR/$tarball_name" "$(basename "$temp_dir")")

    # Cleanup
    rm -rf "$temp_dir"

    print_status "success" "Source tarball created: $tarball_name"
}

# Function: Create Homebrew formula
create_homebrew_formula() {
    if [[ "$CREATE_HOMEBREW" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating Homebrew formula..."

    local formula_dir="$OUTPUT_DIR/homebrew"
    mkdir -p "$formula_dir"

    cat > "$formula_dir/${PACKAGE_NAME}.rb" << EOF
class TmuxForceline < Formula
  desc "$DESCRIPTION"
  homepage "$HOMEPAGE"
  url "$HOMEPAGE/archive/v$VERSION.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "$LICENSE"
  version "$VERSION"

  depends_on "tmux" => ">=3.0"
  depends_on "yq"

  def install
    # Install main files
    prefix.install Dir["*"]

    # Make scripts executable
    bin.install_symlink prefix/"install.sh" => "tmux-forceline"

    # Install shell completions if available
    if File.exist?("completions/bash")
      bash_completion.install "completions/bash/tmux-forceline"
    end

    if File.exist?("completions/zsh")
      zsh_completion.install "completions/zsh/_tmux-forceline"
    end
  end

  def post_install
    puts ""
    puts "tmux-forceline v#{version} installed successfully!"
    puts ""
    puts "Next steps:"
    puts "  1. Run: tmux-forceline --profile=auto"
    puts "  2. Reload tmux: tmux source-file ~/.tmux.conf"
    puts ""
    puts "Documentation: #{prefix}/docs/"
    puts ""
  end

  test do
    system bin/"tmux-forceline", "--help"

    # Test tmux integration
    system "tmux", "new-session", "-d", "-s", "test-session"
    system "tmux", "kill-session", "-t", "test-session"
  end
end
EOF

    print_status "success" "Homebrew formula created: homebrew/${PACKAGE_NAME}.rb"
}

# Function: Create Snap package
create_snap_package() {
    if [[ "$CREATE_SNAP" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating Snap package..."

    local snap_dir="$OUTPUT_DIR/snap"
    mkdir -p "$snap_dir"

    cat > "$snap_dir/snapcraft.yaml" << EOF
name: $PACKAGE_NAME
base: core22
version: '$VERSION'
summary: $DESCRIPTION
description: |
  tmux-forceline v3.0 is a revolutionary tmux status bar system featuring:

  - Native tmux format integration (100% performance improvement)
  - Hybrid architecture (60% performance improvement)
  - Adaptive configuration system
  - Cross-platform compatibility (Linux, macOS, BSD)
  - Intelligent caching and background updates
  - Base24 theme system with YAML configuration
  - Modular plugin architecture

grade: stable
confinement: classic

apps:
  tmux-forceline:
    command: bin/install.sh
    environment:
      PATH: \$SNAP/bin:\$SNAP/usr/bin:\$PATH

parts:
  tmux-forceline:
    plugin: dump
    source: $HOMEPAGE/archive/v$VERSION.tar.gz
    organize:
      '*': ./
    stage:
      - -packaging
    override-build: |
      craftctl default
      chmod +x \$CRAFTCTL_PART_INSTALL/install.sh
      chmod +x \$CRAFTCTL_PART_INSTALL/utils/*.sh

  dependencies:
    plugin: nil
    stage-packages:
      - tmux
      - curl
      - git
EOF

    print_status "success" "Snap package created: snap/snapcraft.yaml"
}

# Function: Create Debian package
create_debian_package() {
    if [[ "$CREATE_DEB" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating Debian package..."

    local deb_dir="$OUTPUT_DIR/debian"
    mkdir -p "$deb_dir/DEBIAN"
    mkdir -p "$deb_dir/usr/share/tmux-forceline"
    mkdir -p "$deb_dir/usr/bin"
    mkdir -p "$deb_dir/usr/share/doc/tmux-forceline"

    # Control file
    cat > "$deb_dir/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: tmux (>= 3.0), curl, git
Recommends: yq
Maintainer: $AUTHOR
Description: $DESCRIPTION
 tmux-forceline v3.0 is a revolutionary tmux status bar system featuring
 native tmux format integration for 100% performance improvement,
 adaptive configuration, and cross-platform compatibility.
Homepage: $HOMEPAGE
EOF

    # Install script
    cat > "$deb_dir/DEBIAN/postinst" << 'EOF'
#!/usr/bin/env bash
set -e

echo "Setting up tmux-forceline..."

# Make scripts executable
find /usr/share/tmux-forceline -name "*.sh" -exec chmod +x {} \;

echo ""
echo "tmux-forceline installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Run: tmux-forceline --profile=auto"
echo "  2. Reload tmux: tmux source-file ~/.tmux.conf"
echo ""
echo "Documentation: /usr/share/doc/tmux-forceline/"
echo ""

exit 0
EOF

    chmod +x "$deb_dir/DEBIAN/postinst"

    # Copy files
    cp -r "$PROJECT_DIR"/* "$deb_dir/usr/share/tmux-forceline/"

    # Remove unwanted files
    rm -rf "$deb_dir/usr/share/tmux-forceline/packaging"

    # Create symlink
    ln -s "../share/tmux-forceline/install.sh" "$deb_dir/usr/bin/tmux-forceline"

    # Documentation
    cp "$PROJECT_DIR/README_v3.md" "$deb_dir/usr/share/doc/tmux-forceline/"
    cp -r "$PROJECT_DIR/docs" "$deb_dir/usr/share/doc/tmux-forceline/"

    print_status "success" "Debian package structure created: debian/"
}

# Function: Create RPM spec
create_rpm_spec() {
    if [[ "$CREATE_RPM" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating RPM spec..."

    local rpm_dir="$OUTPUT_DIR/rpm"
    mkdir -p "$rpm_dir"

    cat > "$rpm_dir/${PACKAGE_NAME}.spec" << EOF
Name:           $PACKAGE_NAME
Version:        $VERSION
Release:        1%{?dist}
Summary:        $DESCRIPTION

License:        $LICENSE
URL:            $HOMEPAGE
Source0:        %{name}-%{version}.tar.gz

Requires:       tmux >= 3.0
Requires:       curl
Requires:       git
Recommends:     yq

BuildArch:      noarch

%description
tmux-forceline v3.0 is a revolutionary tmux status bar system featuring
native tmux format integration for 100% performance improvement,
adaptive configuration, and cross-platform compatibility.

%prep
%autosetup

%build
# No build required

%install
mkdir -p %{buildroot}%{_datadir}/%{name}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_docdir}/%{name}

# Copy main files
cp -r * %{buildroot}%{_datadir}/%{name}/

# Remove packaging files
rm -rf %{buildroot}%{_datadir}/%{name}/packaging

# Create symlink
ln -s %{_datadir}/%{name}/install.sh %{buildroot}%{_bindir}/%{name}

# Documentation
cp README_v3.md %{buildroot}%{_docdir}/%{name}/
cp -r docs %{buildroot}%{_docdir}/%{name}/

%post
echo ""
echo "tmux-forceline installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Run: tmux-forceline --profile=auto"
echo "  2. Reload tmux: tmux source-file ~/.tmux.conf"
echo ""
echo "Documentation: %{_docdir}/%{name}/"
echo ""

%files
%{_datadir}/%{name}
%{_bindir}/%{name}
%{_docdir}/%{name}

%changelog
* $(date '+%a %b %d %Y') $AUTHOR - $VERSION-1
- Initial release of tmux-forceline v3.0
- Revolutionary performance improvements with native tmux integration
- Adaptive configuration system
- Cross-platform compatibility
EOF

    print_status "success" "RPM spec created: rpm/${PACKAGE_NAME}.spec"
}

# Function: Create Arch Linux PKGBUILD
create_arch_pkgbuild() {
    if [[ "$CREATE_ARCH" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating Arch Linux PKGBUILD..."

    local arch_dir="$OUTPUT_DIR/arch"
    mkdir -p "$arch_dir"

    cat > "$arch_dir/PKGBUILD" << EOF
# Maintainer: $AUTHOR
pkgname=$PACKAGE_NAME
pkgver=$VERSION
pkgrel=1
pkgdesc="$DESCRIPTION"
arch=('any')
url="$HOMEPAGE"
license=('$LICENSE')
depends=('tmux>=3.0' 'curl' 'git')
optdepends=('yq: YAML theme support')
source=("\$pkgname-\$pkgver.tar.gz::$HOMEPAGE/archive/v\$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "\$srcdir/\$pkgname-\$pkgver"

    # Install main files
    install -dm755 "\$pkgdir/usr/share/\$pkgname"
    cp -r * "\$pkgdir/usr/share/\$pkgname/"

    # Remove packaging files
    rm -rf "\$pkgdir/usr/share/\$pkgname/packaging"

    # Make scripts executable
    find "\$pkgdir/usr/share/\$pkgname" -name "*.sh" -exec chmod +x {} \\;

    # Create binary symlink
    install -dm755 "\$pkgdir/usr/bin"
    ln -s "/usr/share/\$pkgname/install.sh" "\$pkgdir/usr/bin/\$pkgname"

    # Install documentation
    install -dm755 "\$pkgdir/usr/share/doc/\$pkgname"
    install -m644 README_v3.md "\$pkgdir/usr/share/doc/\$pkgname/"
    cp -r docs "\$pkgdir/usr/share/doc/\$pkgname/"
}
EOF

    print_status "success" "Arch Linux PKGBUILD created: arch/PKGBUILD"
}

# Function: Create Nix package
create_nix_package() {
    if [[ "$CREATE_NIX" != "yes" ]]; then
        return
    fi

    print_status "info" "Creating Nix package..."

    local nix_dir="$OUTPUT_DIR/nix"
    mkdir -p "$nix_dir"

    cat > "$nix_dir/default.nix" << EOF
{ lib
, stdenv
, fetchFromGitHub
, tmux
, yq
, curl
, git
, bash
}:

stdenv.mkDerivation rec {
  pname = "$PACKAGE_NAME";
  version = "$VERSION";

  src = fetchFromGitHub {
    owner = "your-org";
    repo = "tmux-forceline";
    rev = "v\${version}";
    sha256 = "REPLACE_WITH_ACTUAL_SHA256";
  };

  buildInputs = [ bash ];

  propagatedBuildInputs = [ tmux yq curl git ];

  dontBuild = true;

  installPhase = ''
    mkdir -p \$out/share/tmux-forceline
    cp -r * \$out/share/tmux-forceline/

    # Remove packaging files
    rm -rf \$out/share/tmux-forceline/packaging

    # Make scripts executable
    find \$out/share/tmux-forceline -name "*.sh" -exec chmod +x {} \\;

    # Create wrapper script
    mkdir -p \$out/bin
    cat > \$out/bin/tmux-forceline << 'WRAPPER'
#!/usr/bin/env bash
exec \$out/share/tmux-forceline/install.sh "\$@"
WRAPPER
    chmod +x \$out/bin/tmux-forceline

    # Install documentation
    mkdir -p \$out/share/doc/tmux-forceline
    cp README_v3.md \$out/share/doc/tmux-forceline/
    cp -r docs \$out/share/doc/tmux-forceline/
  '';

  meta = with lib; {
    description = "$DESCRIPTION";
    homepage = "$HOMEPAGE";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
EOF

    print_status "success" "Nix package created: nix/default.nix"
}

# Function: Generate installation instructions
generate_install_instructions() {
    print_status "info" "Generating installation instructions..."

    cat > "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
# tmux-forceline v$VERSION Package Installation

## Available Packages

### Source Tarball
\`\`\`bash
wget https://github.com/your-org/tmux-forceline/releases/download/v$VERSION/${PACKAGE_NAME}-${VERSION}.tar.gz
tar -xzf ${PACKAGE_NAME}-${VERSION}.tar.gz
cd ${PACKAGE_NAME}-${VERSION}
./install.sh --profile=auto
\`\`\`

EOF

    if [[ "$CREATE_HOMEBREW" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
### Homebrew (macOS/Linux)
\`\`\`bash
brew tap your-org/tmux-forceline
brew install tmux-forceline
tmux-forceline --profile=auto
\`\`\`

EOF
    fi

    if [[ "$CREATE_SNAP" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
### Snap (Linux)
\`\`\`bash
sudo snap install tmux-forceline --classic
tmux-forceline --profile=auto
\`\`\`

EOF
    fi

    if [[ "$CREATE_DEB" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
### Debian/Ubuntu
\`\`\`bash
wget https://github.com/your-org/tmux-forceline/releases/download/v$VERSION/${PACKAGE_NAME}_${VERSION}_all.deb
sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_all.deb
sudo apt-get install -f  # Fix dependencies if needed
tmux-forceline --profile=auto
\`\`\`

EOF
    fi

    if [[ "$CREATE_RPM" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
### RHEL/Fedora/CentOS
\`\`\`bash
wget https://github.com/your-org/tmux-forceline/releases/download/v$VERSION/${PACKAGE_NAME}-${VERSION}-1.noarch.rpm
sudo rpm -i ${PACKAGE_NAME}-${VERSION}-1.noarch.rpm
tmux-forceline --profile=auto
\`\`\`

EOF
    fi

    if [[ "$CREATE_ARCH" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
### Arch Linux
\`\`\`bash
yay -S tmux-forceline
# or manually:
git clone https://aur.archlinux.org/tmux-forceline.git
cd tmux-forceline
makepkg -si
tmux-forceline --profile=auto
\`\`\`

EOF
    fi

    if [[ "$CREATE_NIX" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
### NixOS/Nix
\`\`\`nix
# In configuration.nix or home.nix
{
  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      {
        plugin = tmux-forceline;
        extraConfig = ''
          set -g @forceline_theme "catppuccin-frappe"
          set -g @forceline_auto_profile "yes"
        '';
      }
    ];
  };
}
\`\`\`

EOF
    fi

    cat >> "$OUTPUT_DIR/INSTALL_PACKAGES.md" << EOF
## Verification

After installation, verify the setup:
\`\`\`bash
tmux-forceline --help
tmux -V  # Should show 3.0+
yq --version  # Should show 4.0+
\`\`\`

## Quick Start

1. **Auto-configure**: \`tmux-forceline --profile=auto\`
2. **Reload tmux**: \`tmux source-file ~/.tmux.conf\`
3. **Enjoy**: Experience 100% performance improvement!

EOF

    print_status "success" "Installation instructions created: INSTALL_PACKAGES.md"
}

# Function: Create release checklist
create_release_checklist() {
    print_status "info" "Creating release checklist..."

    cat > "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
# tmux-forceline v$VERSION Release Checklist

## Pre-Release Verification

### Code Quality
- [ ] All tests pass
- [ ] Performance validation successful
- [ ] Cross-platform compatibility verified
- [ ] Documentation is up-to-date
- [ ] Version numbers updated everywhere

### Package Testing
- [ ] Source tarball extracts and installs correctly
EOF

    if [[ "$CREATE_HOMEBREW" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] Homebrew formula tested on macOS
- [ ] Homebrew formula tested on Linux
EOF
    fi

    if [[ "$CREATE_SNAP" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] Snap package builds successfully
- [ ] Snap package installs and runs correctly
EOF
    fi

    if [[ "$CREATE_DEB" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] Debian package builds with dpkg-deb
- [ ] Package installs on Ubuntu LTS
- [ ] Package installs on Debian stable
EOF
    fi

    if [[ "$CREATE_RPM" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] RPM builds with rpmbuild
- [ ] Package installs on RHEL/CentOS
- [ ] Package installs on Fedora
EOF
    fi

    if [[ "$CREATE_ARCH" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] PKGBUILD validated with namcap
- [ ] Package builds and installs on Arch Linux
EOF
    fi

    if [[ "$CREATE_NIX" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] Nix package builds successfully
- [ ] Package works on NixOS
- [ ] Package works with Home Manager
EOF
    fi

    cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF

## Release Process

### GitHub Release
- [ ] Tag created: v$VERSION
- [ ] Release notes written
- [ ] Assets uploaded:
EOF

    if [[ "$CREATE_TARBALL" == "yes" ]]; then
        echo "  - [ ] ${PACKAGE_NAME}-${VERSION}.tar.gz" >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md"
    fi

    if [[ "$CREATE_DEB" == "yes" ]]; then
        echo "  - [ ] ${PACKAGE_NAME}_${VERSION}_all.deb" >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md"
    fi

    if [[ "$CREATE_RPM" == "yes" ]]; then
        echo "  - [ ] ${PACKAGE_NAME}-${VERSION}-1.noarch.rpm" >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md"
    fi

    cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF

### Package Manager Distribution
EOF

    if [[ "$CREATE_HOMEBREW" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] Homebrew tap updated
- [ ] Formula SHA256 updated
- [ ] Homebrew CI passes
EOF
    fi

    if [[ "$CREATE_SNAP" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] Snap uploaded to store
- [ ] Snap approved and published
EOF
    fi

    if [[ "$CREATE_ARCH" == "yes" ]]; then
        cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF
- [ ] AUR package updated
- [ ] PKGBUILD SHA256 updated
EOF
    fi

    cat >> "$OUTPUT_DIR/RELEASE_CHECKLIST.md" << EOF

### Documentation
- [ ] Website updated
- [ ] Installation guide reflects new packages
- [ ] Changelog updated
- [ ] Social media announcements prepared

### Post-Release
- [ ] Monitor for installation issues
- [ ] Respond to user feedback
- [ ] Update documentation based on feedback

EOF

    print_status "success" "Release checklist created: RELEASE_CHECKLIST.md"
}

# Function: Main distribution process
main() {
    print_status "header" "tmux-forceline v$VERSION Distribution Creator"
    echo

    parse_arguments "$@"
    setup_output_dir

    # Create packages
    create_source_tarball
    create_homebrew_formula
    create_snap_package
    create_debian_package
    create_rpm_spec
    create_arch_pkgbuild
    create_nix_package

    # Generate documentation
    generate_install_instructions
    create_release_checklist

    # Summary
    echo
    print_status "success" "Distribution packages created in: $OUTPUT_DIR"
    echo
    print_status "info" "Created packages:"
    find "$OUTPUT_DIR" -type f \( -name "*.tar.gz" -o -name "*.rb" -o -name "*.yaml" -o -name "control" -o -name "*.spec" -o -name "PKGBUILD" -o -name "default.nix" \) | sed 's|.*/|  • |'
    echo
    print_status "info" "Next steps:"
    echo "  1. Review generated packages"
    echo "  2. Test installation on target platforms"
    echo "  3. Update SHA256 hashes in package files"
    echo "  4. Follow RELEASE_CHECKLIST.md"
    echo
}

# Run main function
main "$@"
