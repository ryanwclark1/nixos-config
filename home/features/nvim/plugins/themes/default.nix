{
  colorschemes = {
    catppuccin = {
      enable = true;
      settings = {
        dim_inactive = {
          enabled = false;
          percentage = 0.25;
        };
        # background = {
        #   light = "macchiato";
        #   dark = "mocha";
        # };
        custom_highlights = ''
          function(highlights)
            return {
            CursorLineNr = { fg = highlights.peach, style = {} },
            NavicText = { fg = highlights.text },
            }
          end
        '';
        flavour = "macchiato"; # "latte", "mocha", "frappe", "macchiato" or raw lua code
        no_bold = false;
        no_italic = false;
        no_underline = false;
        transparent_background = true;
        integrations = {
          aerial = true;
          cmp = true;
          gitsigns = true;
          illuminate = {
            enabled = true;
            lsp = true;
          };
          indent_blankline.enabled = true;
          mini = {
            enabled = true;
            # indentscope_color = "rosewater";
          };
          navic = {
            enabled = true;
            custom_bg = "NONE";
          };
          native_lsp = {
            enabled = true;
            inlay_hints = {
              background = true;
            };
            virtual_text = {
              errors = ["italic"];
              hints = ["italic"];
              information = ["italic"];
              warnings = ["italic"];
              ok = ["italic"];
            };
            underlines = {
              errors = ["underline"];
              hints = ["underline"];
              information = ["underline"];
              warnings = ["underline"];
            };
          };
          neotree = true;
          notify = true;
          semantic_tokens = true;
          symbols_outline = true;
          telescope = {
            enabled = true;
            theme = "nvchad";
          };
          treesitter = true;
          which_key = true;
        };
      };
    };
  };
}
