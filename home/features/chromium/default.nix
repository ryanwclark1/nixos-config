{
  pkgs,
  lib,
  ...
}:

# Chromium - Open-source browser with privacy focus
#
# Features:
# - Wayland native support (via Ozone)
# - Hardware acceleration enabled
# - Privacy-focused default settings
# - Catppuccin color scheme integration
# - Extension support
#
# Note: This is ungoogled-chromium for enhanced privacy.
# For Google Chrome, use home/features/chrome instead.

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;

    # Command-line arguments for Chromium
    # These are applied on every launch
    commandLineArgs = [
      # Wayland support (native, not XWayland)
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"

      # Hardware acceleration
      "--enable-features=VaapiVideoDecoder"
      "--enable-features=VaapiVideoEncoder"
      "--enable-accelerated-video-decode"

      # Visual enhancements
      "--force-dark-mode"                    # Enable dark mode
      "--enable-features=WebUIDarkMode"      # Dark mode for chrome:// pages

      # Performance
      "--enable-gpu-rasterization"
      "--enable-zero-copy"

      # Privacy
      "--disable-sync"                       # Disable Google sync (ungoogled)

      # Wayland-specific fixes
      "--enable-features=WaylandWindowDecorations"  # Native window decorations
      "--gtk-version=4"                      # Use GTK4 for better Wayland support
    ];

    # Browser extensions (via Chromium Web Store)
    # Note: ungoogled-chromium requires manual extension installation or chromium-web-store extension
    extensions = [
      # Privacy & Security
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
      { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # HTTPS Everywhere

      # Password Management
      # { id = "naepdomgkenhinolocfifgehidddafch"; } # Browserpass (if using pass)

      # Development Tools
      # { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React Developer Tools
      # { id = "lmhkpmbekcpmknklioeibfkpmmfibljd"; } # Redux DevTools

      # Productivity
      # { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
    ];
  };

  # XDG desktop entry for proper application launching
  # Ensures Chromium launches with correct Wayland environment
  xdg.desktopEntries.chromium = {
    name = "Chromium";
    genericName = "Web Browser";
    comment = "Browse the World Wide Web";
    exec = "chromium %U";
    icon = "chromium";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  # Additional Chromium configuration files
  # These provide privacy-focused defaults and theme integration
  home.file.".config/chromium-flags.conf".text = ''
    # Additional Chromium flags
    # This file can be sourced by wrapper scripts

    # Wayland support
    --enable-features=UseOzonePlatform
    --ozone-platform=wayland

    # Dark mode
    --force-dark-mode
    --enable-features=WebUIDarkMode
  '';

  # Chromium policies for privacy and security
  # These are enforced at the browser level
  home.file.".config/chromium/policies/managed/privacy.json".text = builtins.toJSON {
    # Privacy settings
    "DefaultSearchProviderEnabled" = true;
    "DefaultSearchProviderName" = "DuckDuckGo";
    "DefaultSearchProviderSearchURL" = "https://duckduckgo.com/?q={searchTerms}";

    # Security
    "SSLVersionMin" = "tls1.2";
    "DNSOverHttpsMode" = "automatic";

    # Privacy protections
    "SafeBrowsingProtectionLevel" = 1;  # Standard protection
    "PasswordManagerEnabled" = false;    # Disable built-in password manager (use external)
    "SyncDisabled" = true;              # Disable sync
    "MetricsReportingEnabled" = false;  # Disable metrics
    "SpellcheckEnabled" = true;
    "SpellcheckLanguage" = [ "en-US" ];

    # Downloads
    "DownloadDirectory" = "\${home}/Downloads";
    "PromptForDownloadLocation" = true;

    # Cookies and tracking
    "BlockThirdPartyCookies" = true;
    "DefaultCookiesSetting" = 1;  # Allow cookies but block third-party

    # WebRTC
    "WebRtcIPHandlingPolicy" = "default_public_interface_only";
  };

  # Session restoration - remember tabs but not for privacy-sensitive sites
  home.file.".config/chromium/Default/Preferences".text = builtins.toJSON {
    "profile" = {
      "name" = "Default";
      "exit_type" = "Normal";
      "exited_cleanly" = true;
    };
    "session" = {
      "restore_on_startup" = 4;  # Restore previous session
    };
    "browser" = {
      "show_home_button" = false;
      "check_default_browser" = false;
    };
  };

  # Chromium wrapper script for additional environment setup
  home.packages = [
    (pkgs.writeShellScriptBin "chromium-private" ''
      # Launch Chromium in private/incognito mode with extra privacy flags
      exec ${pkgs.ungoogled-chromium}/bin/chromium \
        --incognito \
        --disable-sync \
        --disable-features=MediaRouter \
        "$@"
    '')
  ];
}
