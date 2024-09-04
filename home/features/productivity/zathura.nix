{
  config,
  ...
}:
with config.stylix.fonts;

{
  programs.zathura = {
    enable = true;

   options = {
      ###########
      # Options #
      ###########
      font = "${monospace.name}";
      adjust-open = "width";
      pages-per-row = 1;
      selection-clipboard = "clipboard";
      incremental-search = true;
      recolor = true;

      window-title-home-tilde = true;
      window-title-basename = true;
      statusbar-home-tilde = true;
      show-hidden = true;

      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;

    };

    ################
    # Key mappings #
    ################
    mappings = {
      K = "zoom in";
      J = "zoom out";

      r = "reload";
      R = "rotate";

      u = "scroll half-up";
      d = "scroll half-down";

      D = "toggle_page_mode";

      i = "recolor";

      # next/previous page
      H = "navigate previous";
      L = "navigate next";

      "<Right>" = "navigate next";
      "<Left>" = "navigate previous";
      "<Down>" = "scroll down";
      "<Up>" = "scroll up";
    };
  };
}
