{
  programs.nixvim.plugins = {
    alpha = {
      enable = true;
      iconsEnabled = true;
      layout = [
        {
          type = "padding";
          val = 4;
        }
        {
          type = "text";
          val = [
            "                                                                     "
            "       ████ ██████           █████      ██                     "
            "      ███████████             █████                             "
            "      █████████ ███████████████████ ███   ███████████   "
            "     █████████  ███    █████████████ █████ ██████████████   "
            "    █████████ ██████████ █████████ █████ █████ ████ █████   "
            "  ███████████ ███    ███ █████████ █████ █████ ████ █████  "
            " ██████  █████████████████████ ████ █████ █████ ████ ██████ "
            "                                                                       "
          ];
          opts = {
            position = "center";
            hl = "Type";
          };
        }
        {
          type = "padding";
          val = 2;
        }
        {
          type = "button";
          val = "󰈔  New file";
          on_press.__raw = "function() vim.cmd[[enew]] end";
          opts = {
            shortcut = "SPC z n";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "  Recent files";
          on_press.__raw = "require('telescope.builtin').oldfiles";
          opts = {
						shortcut = "SPC z r";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "  Find files";
          on_press.__raw = "require('telescope.builtin').find_files";
          opts = {
						shortcut = "SPC z f";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "󰾹  Find word";
          on_press.__raw = "require('telescope.builtin').live_grep";
          opts = {
						shortcut = "SPC z w";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "  File Browser";
          on_press.__raw = "require('telescope.builtin').file_browser";
          opts = {
						shortcut = "SPC z e";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        # {
        #   type = "button";
        #   val = "  Copilot Chat";
        #   on_press.__raw = "require('copilot-chat')";
        #   opts = {
				#     shortcut = "SPC z t";
        #     position = "center";
        #     cursor = 3;
        #     width = 38;
        #     align_shortcut = "right";
        #     hl_shortcut = "Keyword";
        #   };
        # }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "  Scratchpad";
          on_press.__raw = "function() vim.cmd[[e ~/Documents/Notes/scratch.md]] end";
          opts = {
            shortcut = "SPC z p";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "  Check Health";
          on_press.__raw = "function() vim.cmd[[checkhealth]] end";
          opts = {
            shortcut = "SPC z c";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "button";
          val = "  Exit";
          on_press.__raw = "function() vim.cmd[[qa]] end";
          opts = {
            shortcut = "SPC z q";
            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        {
          type = "padding";
          val = 3;
        }
        {
          type = "text";
          val = "HI!";
          opts = {
            position = "center";
            hl = "keyword";
          };
        }
      ];
    };
  };
}