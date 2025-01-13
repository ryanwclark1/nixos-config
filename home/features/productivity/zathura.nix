{
  config,
  ...
}:

{
  programs.zathura = {
    enable = true;

   options = {
      ###########
      # Options #
      ###########
      font = "${config.stylix.fonts.monospace.name}";

      abort-clear-search = true;
      adjust-open = "best-fit";
      advance-pages-per-row = "false";
      database = "sqlite";
      dbus-service = true;
      incremental-search = true;

      page-padding = 1;
      page-cache-size = 15;
      page-thumbnail-size = 4194304;
      pages-per-row = 1;

      render-loading = true;

      scroll-hstep = -1;
      scroll-step = 40;
      scroll-full-overlap = 0;
      scroll-wrap = false;

      show-directories = true;
      show-hidden = true;
      show-recent = 10;

      scroll-page-aware = false;
      smooth-scroll = false;

      link-zoom = true;
      link-hadjust = true;

      search-hadjust = true;

      window-title-basename = false;
      window-title-home-tilde = true;
      window-title-page = false;

      statusbar-basename = false;
      statusbar-home-tilde = true;

      zoom-center = false;
      zoom-max = 1000;
      zoom-min = 10;
      zoom-step = 10;

      selection-clipboard = "clipboard";
      selection-notification = true;

      statusbar-h-padding = 0;
      statusbar-v-padding = 0;

      default-fg = "rgba(198,208,245,1)";
      default-bg = "rgba(48,52,70,1)";

      completion-bg = "rgba(65,69,89,1)";
      completion-fg = "rgba(198,208,245,1)";
      completion-highlight-bg = "rgba(87,82,104,1)";
      completion-highlight-fg = "rgba(198,208,245,1)";
      completion-group-bg = "rgba(65,69,89,1)";
      completion-group-fg = "rgba(140,170,238,1)";

      statusbar-fg = "rgba(198,208,245,1)";
      statusbar-bg = "rgba(65,69,89,1)";

      notification-bg = "rgba(65,69,89,1)";
      notification-fg = "rgba(198,208,245,1)";
      notification-error-bg = "rgba(65,69,89,1)";
      notification-error-fg = "rgba(231,130,132,1)";
      notification-warning-bg = "rgba(65,69,89,1)";
      notification-warning-fg = "rgba(250,227,176,1)";

      inputbar-fg = "rgba(198,208,245,1)";
      inputbar-bg = "rgba(65,69,89,1)";

      recolor = true;
      recolor-lightcolor = "rgba(48,52,70,1)";
      recolor-darkcolor = "rgba(198,208,245,1)";

      index-fg = "rgba(198,208,245,1)";
      index-bg = "rgba(48,52,70,1)";
      index-active-fg = "rgba(198,208,245,1)";
      index-active-bg = "rgba(65,69,89,1)";

      render-loading-bg = "rgba(48,52,70,1)";
      render-loading-fg = "rgba(198,208,245,1)";

      highlight-color = "rgba(87,82,104,0.5)";
      highlight-fg = "rgba(244,184,228,0.5)";
      highlight-active-color = "rgba(244,184,228,0.5)";
    };

    ################
    # Key mappings #
    ################
    # mappings = {
    #   K = "zoom in";
    #   J = "zoom out";

    #   r = "reload";
    #   R = "rotate";

    #   u = "scroll half-up";
    #   d = "scroll half-down";

    #   D = "toggle_page_mode";

    #   i = "recolor";

    #   # next/previous page
    #   H = "navigate previous";
    #   L = "navigate next";

    #   "<Right>" = "navigate next";
    #   "<Left>" = "navigate previous";
    #   "<Down>" = "scroll down";
    #   "<Up>" = "scroll up";
    # };
  };
}
