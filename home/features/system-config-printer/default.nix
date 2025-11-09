{
  pkgs,
  ...
}:

# system-config-printer - Printer configuration GUI
#
# A graphical tool to configure CUPS printers and manage print queues.
# Integrates with the CUPS printing system configured at the system level.
#
# Features:
# - Add and remove printers
# - Configure printer settings and defaults
# - Manage print queues and jobs
# - Install printer drivers
# - Troubleshoot printer issues
#
# Prerequisites:
# - CUPS printing service must be enabled (hosts/common/optional/services/printing.nix)
# - Avahi service for network printer discovery
#
# Usage:
# - Launch from application menu or run `system-config-printer`
# - CUPS web interface also available at http://localhost:631

{
  home.packages = with pkgs; [
    system-config-printer  # GTK+ printer configuration tool
  ];
}
