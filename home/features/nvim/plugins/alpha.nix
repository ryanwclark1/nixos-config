{
  ...
}:

{
  programs.nixvim.plugins = {
    alpha = {
      enable = true;
      iconsEnabled = true;
      layout = [
        {
          type = "padding";
          val = 2;
        }
        {
          opts = {
            hl = "Type";
            position = "center";
          };
          type = "text";
          val = [
              "                                                     "
              "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ "
              "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ "
              "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ "
              "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ "
              "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ "
              "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ "
              "                                                     "
          ];
        }
        {
          type = "padding";
          val = 2;
        }
        {
          opts = {
            hl = "Type";
            position = "center";
          };
          type = "group";
          val = [
            {
              on_press = {
                __raw = "function() vim.cmd[[enew]] end";
              };
              opts = {
                shortcut = "n";
              };
              type = "button";
              val = " 󰈔 New file";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[Explore]] end";
              };
              opts = {
                shortcut = "e";
              };
              type = "button";
              val = "  Explore";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[Git | only]] end";
              };
              opts = {
                shortcut = "g";
              };
              type = "button";
              val = "  Git summary";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[e ~/Documents/Notes/scratch.md]] end";
              };
              opts = {
                shortcut = "s";
              };
              type = "button";
              val = "  Scratchpad";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[e ~/nix-config/flake.nix]] end";
              };
              opts = {
                shortcut = "c";
              };
              type = "button";
              val = "   Nix config flake";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[checkhealth]] end";
              };
              opts = {
                shortcut = "c";
              };
              type = "button";
              val = "   Check health";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[qa]] end";
              };
              opts = {
                shortcut = "q";
              };
              type = "button";
              val = " 󰅙  Quit nvim";
            }

          ];
        }
      ];
    };
  };
}