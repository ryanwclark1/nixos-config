{
  config,
  ...
}:

{
  programs.browserpass.enable = true;
  programs.firefox = {
    enable = true;
    profiles.${config.home.username} = {
      bookmarks = { };
      # extensions = with pkgs.inputs.firefox-addons; [
      #   ublock-origin
      #   browserpass
      # ];
      bookmarks = { };
      settings = {
        browser = {
          "disableResetPrompt" = true;
          "download.panel.shown" = true;
          "download.useDownloadDir" = false;
          "newtabpage.activity-stream.showSponsoredTopSites" = false;
          "shell.checkDefaultBrowser" = false;
          "shell.defaultBrowserCheckCount" = 1;
          "startup.homepage" = "https://start.duckduckgo.com";
          "tabs.loadInBackground" = true;
          "uiCustomization.state" = ''
            {"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":18,"newElementCount":4}
          '';
        };
        "dom.security.https_only_mode" = true;
        "identity.fxaccounts.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "signon.rememberSignons" = false;
      };
    };
  };
}
