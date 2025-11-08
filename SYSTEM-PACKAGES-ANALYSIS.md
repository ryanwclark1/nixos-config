# System-Level Package Analysis

Analysis of Omarchy missing packages for NixOS system configuration.

Generated: 2025-11-08
Branch: claude/add-omarchy-features-011CUw3Nwc7RptSXMpZRHU48

## Package Status Overview

### ✅ Already Configured

| Package | Status | Location | Notes |
|---------|--------|----------|-------|
| **nss-mdns** | ✅ Configured | `hosts/common/optional/services/printing.nix:10` | Via `services.avahi.nssmdns4 = true` |
| **avahi** | ✅ Enabled | `hosts/common/optional/services/printing.nix:7-17` | Full service with publishing enabled |
| **plymouth** | ✅ Available | `hosts/common/optional/desktop/plymouth/default.nix` | Custom theme configured, ready to enable |
| **cups** | ✅ Enabled | `hosts/common/optional/services/printing.nix:20-66` | Full printing stack with drivers |

### 📦 Available in Nixpkgs (Need to Add)

| Package | Type | Installation Level | Priority |
|---------|------|-------------------|----------|
| **power-profiles-daemon** | System Service | System | High (laptops) |
| **system-config-printer** | GUI Application | Home/System | Medium |
| **tzupdate** | CLI Tool | Home | Low |
| **xmlstarlet** | CLI Tool | Home | Low |

---

## Detailed Package Information

### 1. nss-mdns (mDNS/Zeroconf Support)

**Status:** ✅ Already Configured

**Current Configuration:**
```nix
# File: hosts/common/optional/services/printing.nix
services.avahi = {
  enable = true;
  openFirewall = true;
  nssmdns4 = true;  # This enables nss-mdns support
  publish = {
    enable = true;
    addresses = true;
    workstation = true;
    userServices = true;
  };
};
```

**What it does:**
- Enables mDNS (Multicast DNS) name resolution
- Allows `.local` domain resolution
- Required for network printer discovery and local network service discovery

**Action Required:** None - already working

---

### 2. Plymouth (Boot Splash Screen)

**Status:** ✅ Available (Not Enabled by Default)

**Current Configuration:**
```nix
# File: hosts/common/optional/desktop/plymouth/default.nix
boot.plymouth = {
  enable = true;
  logo = logo;
  themePackages = [ theme ];
  theme = "custom";
};
```

**How to Enable:**

Add to your host configuration (e.g., `hosts/woody/default.nix` or `hosts/frametop/default.nix`):

```nix
{
  imports = [
    # ... other imports ...
    ../common/optional/desktop/plymouth
  ];
}
```

**What it does:**
- Shows graphical boot splash screen
- Hides boot messages for cleaner boot experience
- Uses NixOS snowflake logo with custom animation

**Priority:** Low - Aesthetic only

---

### 3. Power-Profiles-Daemon

**Status:** ❌ Not Configured (Recommended for Laptops)

**NixOS Package:** `power-profiles-daemon`

**How to Add:**

Create new file: `hosts/common/optional/services/power-profiles.nix`

```nix
{ ... }:

{
  services.power-profiles-daemon = {
    enable = true;
  };
}
```

Then import in laptop configs (e.g., `hosts/frametop/default.nix`):

```nix
{
  imports = [
    # ... other imports ...
    ../common/optional/services/power-profiles
  ];
}
```

**What it does:**
- Manages CPU power profiles (performance, balanced, power-saver)
- Integrates with GNOME, KDE, and other DEs
- Better battery life management on laptops

**Conflicts with:**
- `services.tlp` (cannot use both)
- `services.auto-cpufreq`

**Priority:** High for laptops, Not applicable for desktops

---

### 4. system-config-printer (CUPS GUI)

**Status:** ❌ Not Installed (Optional)

**NixOS Package:** `system-config-printer`

**How to Add:**

Option A - System-wide (available to all users):

```nix
# Add to hosts/common/optional/desktop/common/default.nix
environment.systemPackages = with pkgs; [
  system-config-printer  # Graphical printer configuration
];
```

Option B - Per-user (home-manager):

```nix
# Add to home/features/desktop/common/default.nix
home.packages = with pkgs; [
  system-config-printer
];
```

**What it does:**
- GTK-based graphical interface for managing CUPS printers
- Add, remove, and configure printers via GUI
- Alternative to CUPS web interface (localhost:631)

**Note:** Your CUPS service is already fully configured with web interface at `localhost:631`. This package just provides a native GUI alternative.

**Priority:** Medium - Only needed if you prefer GUI over web interface

---

### 5. tzupdate (Automatic Timezone Updater)

**Status:** ❌ Not Needed (NixOS handles this declaratively)

**NixOS Alternative:**
```nix
# File: hosts/common/global/core/locale.nix (already exists)
time.timeZone = "America/New_York";  # Set declaratively
```

**Recommendation:**
- **Do not install** - NixOS manages timezone through configuration
- Use `timedatectl set-timezone <zone>` if you need to change it temporarily
- Update `time.timeZone` in your config for permanent changes

**Priority:** Not Applicable - NixOS has better built-in solution

---

### 6. xmlstarlet (XML CLI Tool)

**Status:** ❌ Not Installed

**NixOS Package:** `xmlstarlet`

**How to Add (Home-Manager):**

```nix
# Add to home/features/desktop/common/default.nix
home.packages = with pkgs; [
  # ... existing packages ...
  xmlstarlet  # XML command-line toolkit
];
```

**What it does:**
- Command-line XML parsing and manipulation
- XPath queries
- XSLT transformations
- XML validation

**Priority:** Low - Only needed if you work with XML files frequently

---

## Installation Recommendations

### High Priority (Recommended)

1. **power-profiles-daemon** (Laptop only)
   - Location: System (`hosts/common/optional/services/`)
   - Benefit: Significant battery life improvement

2. **Plymouth** (Optional - already available)
   - Location: System (already in `hosts/common/optional/desktop/plymouth/`)
   - Benefit: Cleaner boot experience
   - Action: Just enable in host imports

### Medium Priority

3. **system-config-printer**
   - Location: Home or System
   - Benefit: GUI alternative to CUPS web interface
   - Consider if: You frequently add/remove printers

### Low Priority

4. **xmlstarlet**
   - Location: Home
   - Benefit: XML manipulation from command line
   - Consider if: You regularly work with XML files

### Not Recommended

5. **tzupdate**
   - Reason: NixOS has better declarative timezone management
   - Alternative: Use `time.timeZone` in configuration

6. **nss-mdns**
   - Reason: Already configured via Avahi

---

## Quick Implementation Guide

### To Add power-profiles-daemon (Laptop Only):

```bash
# 1. Create the service file
cat > hosts/common/optional/services/power-profiles.nix << 'EOF'
{ ... }:

{
  services.power-profiles-daemon.enable = true;
}
EOF

# 2. Add to laptop host (e.g., frametop)
# Edit: hosts/frametop/default.nix
# Add:    ../common/optional/services/power-profiles
# to the imports section
```

### To Enable Plymouth:

```bash
# Just add to your host imports
# Edit: hosts/woody/default.nix or hosts/frametop/default.nix
# Add:    ../common/optional/desktop/plymouth
# to the imports section
```

### To Add CLI Tools (xmlstarlet):

```bash
# Edit: home/features/desktop/common/default.nix
# Add to home.packages:
#   xmlstarlet
```

---

## Summary

| Package | Action | Priority |
|---------|--------|----------|
| nss-mdns | ✅ Already working | - |
| avahi | ✅ Already enabled | - |
| plymouth | 🔵 Enable if desired | Low |
| power-profiles-daemon | ⭐ Add for laptops | High |
| system-config-printer | 🔵 Add if needed | Medium |
| tzupdate | ❌ Skip | - |
| xmlstarlet | 🔵 Add if needed | Low |

**Legend:**
- ✅ No action needed
- ⭐ Highly recommended
- 🔵 Optional but useful
- ❌ Not recommended
