{
  config,
  lib,
  pkgs,
  ...
}:

with lib; {
  options.firefox.enable = mkEnableOption "firefox settings";

  config = mkIf config.firefox.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox-wayland.override {
        cfg = {
          forceWayland = true;
          extraPolicies = {
            ExtensionSettings = {};
          };

          pipewireSupport = true;
        };
      };
      profiles = {
        default = {
          name = "default";
          # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          #   adnauseam
          #   bitwarden
          #   clearurls
          #   enhanced-github

          #   switchyomega
          #   i-dont-care-about-cookies
          #   # snowflake
          #   sponsorblock
          #   stylus
          #   tabliss
          # ];

          bookmarks = [
            {
              name = "home-manager options search";
              keyword = "nix";
              url = "https://mipmip.github.io/home-manager-option-search/";
            }
            {
              name = "save to feedbin";
              keyword = "feedbin";
              url = "javascript:void%20(function()%20{%20%20%20%20var%20script%20=%20document.createElement(%22script%22);%20%20%20%20var%20body%20=%20document.querySelector(%22body%22);%20%20%20%20var%20title%20=%20document.title;%20%20%20%20document.title%20=%20%22Sending%20to%20Feedbin:%20%22%20+%20title;%20%20%20%20script.type%20=%20%22text/javascript%22;%20%20%20%20script.async%20=%20true;%20%20%20%20script.src%20=%20%22https://feedbin.com/bookmarklet/replace_me%22.replace(%22replace_me%22,%20Date.now());%20%20%20%20script.setAttribute(%22data-feedbin-token%22,%20%228fd4869ef0c02129c5f86a85e10a1f2f%22);%20%20%20%20script.setAttribute(%22data-original-title%22,%20title);%20%20%20%20script.onerror%20=%20function()%20{%20%20%20%20%20%20%20window.location%20=%20%22https://feedbin.com/pages?url=%22%20+%20encodeURIComponent(window.location.href)%20+%20%22&title=%22%20+%20encodeURIComponent(title)%20+%20%22&page_token=8fd4869ef0c02129c5f86a85e10a1f2f%22;%20%20%20%20%20%20%20document.title%20=%20title;%20%20%20%20};%20%20%20%20body.appendChild(script);})();";
            }
          ];

          isDefault = true;
          settings = {
            "browser.startup.homepage" = "https://feedbin.com";

            # --- UI
            "browser.search.separatePrivateDefault.urlbarResult.enabled" = false;
            "devtools.theme" = "dark";
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # --- pocket
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "extensions.pocket.enabled" = false;
            "extensions.pocket.showHome" = false;

            # --- newtab
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSearch" = false;

            # --- bookmarking
            "browser.bookmarks.addedImportButton" = false;
            "browser.bookmarks.restore_default_bookmarks" = false;

            # --- behavior
            "browser.contentblocking.category" = "standard";
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;
            "network.trr.confirmation_telemetry_enabled" = false;

            # --- to avoid location personalization which I hate
            "browser.search.region" = "US";
            "browser.search.isUS" = true;
            "distribution.searchplugins.defaultLocale" = "en-US";
            "general.useragent.locale" = "en-US";
            "browser.region.update.region" = "US";
            #--- pocket should be off

            "browser.newtabpage.activity-stream.discoverystream.saveToPocketCard.enabled" = false;
            "browser.newtabpage.activity-stream.discoverystream.sendToPocket.enabled" = false;
            "services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
            "browser.newtabpage.activity-stream.default.sites" = ["https://kagi.com" "https://feedbin.com" "https://fosstodon.org"];

            #-------
            "browser.newtabpage.pinned" = [
              {
                title = "kagi";
                url = "https://kagi.com";
              }
              {
                title = "feedbin";
                url = "https://feedbin.com";
              }
              {
                title = "fosstodon";
                url = "https://fosstodon.org";
              }
            ];
          };

          userChrome = ''
             #fullscr-toggler { background-color: rgba(0, 0, 0, 0) !important; }
             :root {
               --toolbarbutton-border-radius: 0px;
               --uc-bg-color: ${config.colors.macchiato.base.hex};
               --uc-show-new-tab-button: none;
               --uc-show-tab-separators: none;
               --uc-tab-separators-color: none;
               --uc-tab-separators-width: none;
               --uc-tab-fg-color: ${config.colors.macchiato.base.hex};
               --autocomplete-popup-background: var(--mff-bg) !important;
               --default-arrowpanel-background: var(--mff-bg) !important;
               --default-arrowpanel-color: #fefefa !important;
               --lwt-toolbarbutton-icon-fill: var(--mff-icon-color) !important;
               --panel-disabled-color: #f9f9fa80;
               --toolbar-bgcolor: var(--mff-bg) !important;
               --urlbar-separator-color: transparent !important;
               --mff-bg: #1F1D29;
               --mff-icon-color: #9BCED7;
               --mff-nav-toolbar-padding: 8px;
               --mff-sidebar-bg: var(--mff-bg);
               --mff-sidebar-color: #F1CA93;
               --mff-tab-border-radius: 0px;
               --mff-tab-color: #EA6F91;
               --mff-tab-font-family: "${config.global-fonts.main-regular} book";
               --mff-tab-font-size: 11pt;
               --mff-tab-font-weight: 325;
               --mff-tab-height: 32px;
               --mff-tab-pinned-bg: #9BCED7;
               --mff-tab-selected-bg: ${config.colors.macchiato.teal.hex};
               --mff-tab-soundplaying-bg: #9c89b8;
               --mff-urlbar-color: ${config.colors.macchiato.base.hex}!important;
               --mff-urlbar-focused-color: #403C58;
               --mff-urlbar-font-family: "${config.global-fonts.main-regular}";
               --mff-urlbar-font-size: 11pt;
               --mff-urlbar-font-weight: 700;
               --mff-urlbar-results-color: ${config.colors.macchiato.text.hex};
               --mff-urlbar-results-font-family: "${config.global-fonts.main-black}";
               --mff-urlbar-results-font-size: 11pt;
               --mff-urlbar-results-font-weight: 700;
               --mff-urlbar-results-url-color: ${config.colors.macchiato.text.hex};
               --tab-border-radius: 0px;
             }
            * {
              border-radius: 0px!important;
            }

            menu,
            menuitem,
            menucaption,
            menupopup,
            menupopup menuitem,
            menupopup menu,
            menupopup menuseparator {
              background-color: ${config.colors.macchiato.surface1.hex}!important;
            }

            .tab-text.tab-label {
              color: ${config.colors.macchiato.subtext0.hex}!important;
            }

            #tabbrowser-tabs:not([secondarytext-unsupported]) .tab-label-container{
              height: 1.5em;
            }
            #urlbar-input, #urlbar-scheme, .searchbar-textbox{
              color: ${config.colors.macchiato.text.hex}!important;
            }
            #TabsToolbar #firefox-view-button[open] > .toolbarbutton-icon, .tab-background:is([selected], [multiselected]) {
              border: 2px solid  ${config.colors.macchiato.teal.hex}!important;
              background-color:  ${config.colors.macchiato.base.hex}!important;
              background-image: none!important;
              filter: drop-shadow(-5px -5px 0px ${config.colors.macchiato.teal.hex});
            }

            .tab-background {
              border-radius: 0px!important;
            }
             #back-button > .toolbarbutton-icon{
               --backbutton-background: transparent !important;
               border: none !important;
             }

            /* #back-button {
               list-style-image: url("left-arrow.svg") !important;
             }

             #forward-button {
               list-style-image: url("right-arrow.svg") !important;
             }
            */
             /* Options with pixel amounts could need to be adjusted, as this only works for my laptop's display */
             #titlebar {
               -moz-box-ordinal-group: 0 !important;
             }

             .tabbrowser-tab:not([fadein]),
             #tracking-protection-icon-container,
             #identity-box {
               display: none !important;
               border: none !important;
             }
             #urlbar-background, .titlebar-buttonbox-container, #nav-bar, .tabbrowser-tab:not([selected]) .tab-background{
                 background: var(--uc-bg-color) !important;
               border: none !important;
             }
             #urlbar[breakout][breakout-extend] {
                 top: calc((var(--urlbar-toolbar-height) - var(--urlbar-height)) / 2) !important;
                 left: 0 !important;
                 width: 100% !important;
             }

             #urlbar[breakout][breakout-extend] > #urlbar-input-container {
                 height: var(--urlbar-height) !important;
                 padding-block: 0 !important;
                 padding-inline: 0 !important;
             }

             #urlbar[breakout][breakout-extend] > #urlbar-background {
                 animation-name: none !important;
                 box-shadow: none !important;
             }
             #urlbar-background {
               box-shadow: none !important;
             }
             /*#tabs-newtab-button {
               display: var(--uc-show-new-tab-button) !important;
             }*/
             .tabbrowser-tab::after {
               border-left: var(--uc-tab-separators-width) solid var(--uc-tab-separators-color) !important;
               display: var(--uc-show-tab-separators) !important;
             }
             .tabbrowser-tab[first-visible-tab][last-visible-tab]{
               background-color: var(--uc-bar-bg-color) !important;
             }
             .tab-close-button.close-icon {
               display: none !important;
             }
             .tabbrowser-tab:hover .tab-close-button.close-icon {
               display: block !important;
             }
             #urlbar-input {
               text-align: center !important;
             }
             #urlbar-input:focus {
               text-align: left !important;
             }
             #urlbar-container {
               margin-left: 3vw !important;
             }
             #navigator-toolbox {
               border-bottom: 0px solid #ea6f91 !important;
               background: var(--uc-bg-color) !important;
             }

             .urlbar-icon > image {
               fill: var(--mff-icon-color) !important;
               color: var(--mff-icon-color) !important;
             }

             .toolbarbutton-text {
               color: var(--mff-icon-color)  !important;
             }
             .urlbar-icon {
               color: var(--mff-icon-color)  !important;

             }

          '';
          userContent = ''

            /*================ IMPORT COLORS ================*/

            :root {
            	--dark_color1: #30333d;
            	--dark_color2: #292b34;
            	--dark_color3: #585e74;
            	--dark_color4: #30333d;

            	--word_color1: #ccaced;
            	--word_color2: #c0c0c0;
            	--word_color3: #dfd7d7;

            	--light_color1: #e1e0e6;
            	--light_color2: #adabb9;
            	--light_color3: #9795a3;
            	--light_color4: #878492;

            	--other_color1: #332e56;
            	--other_color2: #4b4757;
            	--other_color3: #33313c;
            }
            /*================ LIGHT THEME ================*/
            @media {
            :root:not([style]),
            :root[style*="--lwt-accent-color:rgb(227, 228, 230);"] {
            	--base_color1: var(--light_color1);
            	--base_color2: var(--light_color2);
            	--base_color3: var(--light_color3);
            	--base_color4: var(--light_color4);

            	--outer_color1: var(--other_color1);
            	--outer_color2: var(--other_color2);
            	--outer_color3: var(--other_color3);

            	--orbit_color: var(--dark_color3);
            }
            }
            /*================ DARK THEME ================*/
            @media {
            :root[style*="--lwt-accent-color:rgb(12, 12, 13);"] {
            	--base_color1: var(--dark_color1);
            	--base_color2: var(--dark_color2);
            	--base_color3: var(--dark_color3);
            	--base_color4: var(--dark_color4);

            	--outer_color1: var(--word_color1);
            	--outer_color2: var(--word_color2);
            	--outer_color3: var(--word_color3);

            	--orbit_color: var(--light_color3);
            }
            }

            /*============== PRIVATE THEME ==============*/
            @media {
            :root[privatebrowsingmode=temporary] {
            	--base_color1: #291D4F;
            	--base_color2: #3C3376;
            	--base_color3: #4F499D;
            	--base_color4: #625FC4;

            	--outer_color1: #E571F0;
            	--outer_color2: #D9CAF1;
            	--outer_color3: #FFF5FF;

            	--orbit_color: #B39FE3;
            }
            }

            /*================== FIREFOX BG COLOR ==================*/
            @-moz-document url("about:newtab"), url("about:home"), url("about:blank"), url("about:support"), url("about:config") {
            /*Light*/
            html:not(#ublock0-epicker),
            html:not(#ublock0-epicker) body,
            #newtab-customize-surface1 {
              background-color: var(--light_color1) !important;}
            html {--in-content-page-background: var(--light_color1) !important;}
            .wordmark {fill: #201841 !important;}
            .SnippetBaseContainer {background-color: var(--light_color2) !important;
              color: var(--other_color3) !important;}
            .ASRouterButton {border-radius: 0px !important;}
            /*Dark*/
            html:not(#ublock0-epicker)[lwt-newtab-brighttext],
            html:not(#ublock0-epicker) body[lwt-newtab-brighttext],
            #newtab-customize-surface1[lwt-newtab-brighttext] {
              background-color: var(--dark_color1) !important;}
            html[lwt-newtab-brighttext] {--in-content-page-background: var(--dark_color1) !important;}
            [lwt-newtab-brighttext] .wordmark {fill: #fefafe !important;}
            [lwt-newtab-brighttext] .SnippetBaseContainer {background-color: var(--dark_color2) !important;
              color: var(--word_color3) !important;}
            [lwt-newtab-brighttext] .ASRouterButton {border-radius: 0px !important;}
            }

            /*================== SEARCH BAR ==================*/
            /*Light*/
            .search-wrapper input {
              transition: all 0.3s ease !important;
                background: var(--light_color2) var(--newtab-search-icon) 12px center no-repeat !important;
              background-size: 20px !important;
              border: 1px solid !important;
              border-color: var(--light_color3) !important;
              box-shadow: none !important;
              color: var(--other_color3) !important;
            }
            /*Dark*/
            [lwt-newtab-brighttext] .search-wrapper input {
              transition: all 0.3s ease !important;
                background: var(--dark_color2) var(--newtab-search-icon) 12px center no-repeat !important;
              background-size: 20px !important;
              border: 1px solid !important;
              border-color: var(--dark_color3) !important;
              box-shadow: none !important;
              color: var(--word_color3) !important;
            }
            /*Light*/
            .search-wrapper .search-inner-wrapper:hover input,
            .search-wrapper .search-inner-wrapper:active input,
            .search-wrapper input:focus {
              border-color: var(--light_color4) !important;
            }
            /*Dark*/
            [lwt-newtab-brighttext] .search-wrapper .search-inner-wrapper:hover input,
            [lwt-newtab-brighttext] .search-wrapper .search-inner-wrapper:active input,
            [lwt-newtab-brighttext] .search-wrapper input:focus {
              border-color: var(--dark_color4) !important;
            }
            /*Light*/
            .search-wrapper .search-button,
            .search-wrapper .search-button {
              transition: all 0.3s ease !important;
              fill: var(--other_color3) !important;
            }
            /*Dark*/
            [lwt-newtab-brighttext] .search-wrapper .search-button,
            [lwt-newtab-brighttext] .search-wrapper .search-button {
              transition: all 0.3s ease !important;
              fill: var(--word_color3) !important;
            }
            /*Light*/
            .search-wrapper .search-button:focus,
            .search-wrapper .search-button:hover {
                background-color: var(--light_color4) !important;
            }
            /*Dark*/
            [lwt-newtab-brighttext] .search-wrapper .search-button:focus,
            [lwt-newtab-brighttext] .search-wrapper .search-button:hover {
                background-color: var(--dark_color4) !important;
            }

            /*================== READER VIEW ==================*/
            @-moz-document url-prefix("about:reader") {
              html {
                background: var(--base_color1);
              }
              toolbar > reader-toolbar {
                border-radius: 0px !important;
              }

            /*Dark*/
              body.loaded.dark {
                --toolbar-bgcolor: var(--dark_color2) !important;
                --toolbar-border: var(--dark_color1) !important;
                --toolbar-hover: var(--dark_color3) !important;
                --popup-bgcolor: var(--dark_color2) !important;
                --popup-border: var(--dark_color3) !important;
                --font-color: var(--word_color3) !important;
                --icon-fill: var(--word_color3) !important;
                background: var(--dark_color1) !important;
                --blue-40:var(--word_color1) !important;
                --blue-40-a30:rgba(144,89,255,0.3) !important;
                --active-color:var(--word_color1) !important;
            }
            /*Light*/
              body.loaded.light {
                --toolbar-bgcolor: var(--light_color2) !important;
                --toolbar-border: var(--light_color1) !important;
                --toolbar-hover: var(--light_color3) !important;
                --popup-bgcolor: var(--light_color2) !important;
                --popup-border: var(--light_color3) !important;
                --font-color: var(--other_color3) !important;
                --icon-fill: var(--other_color3) !important;
                background: var(--light_color1) !important;
                --blue-40:var(--other_color1) !important;
                --blue-40-a30:rgba(51,46,86,0.3) !important;
                --active-color:var(--other_color1) !important;

            }
            /*Sepia*/
              body.loaded.sepia {
                --toolbar-bgcolor: var(--light_color2) !important;
                --toolbar-border: var(--light_color1) !important;
                --toolbar-hover: var(--light_color3) !important;
                --popup-bgcolor: var(--light_color2) !important;
                --popup-border: var(--light_color3) !important;
                --font-color: var(--other_color3) !important;
                --icon-fill: var(--other_color3) !important;
                background: var(--light_color1) !important;
            }

              }
          '';

          search = {
            default = "duckduckgo";
            force = true;
            engines = {
              "duckduckgo" = {
                urls = [
                  {template = "https://duckduckgo.com/?q={search}&kp=-2&kl=us-en";}
                ];
              };
              "kagi" = {
                urls = [
                  {template = "https://kagi.com/search?q={searchTerms}";}
                ];
              };
              "you" = {
                urls = [
                  {
                    template = "https://you.com/search?q={searchTerms}";
                  }
                ];
              };

              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = ["@np"];
              };

              "NixOS Wiki" = {
                urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = ["@nw"];
              };
              "Bing".metaData.hidden = true;
            };
          };
        };
      };
    };
  };
}