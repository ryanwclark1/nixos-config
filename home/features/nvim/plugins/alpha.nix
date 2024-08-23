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
          type = "group";
          val = [
            {
              on_press = {
                __raw = "function() vim.cmd[[enew]] end";
              };
              opts = {
                position = "center";
                shortcut = "n";
              };
              type = "button";
              val = " 󰈔 New file     ";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[Explore]] end";
              };
              opts = {
                position = "center";
                shortcut = "e";
              };
              type = "button";
              val = "  Explore        ";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[Git | only]] end";
              };
              opts = {
                position = "center";
                shortcut = "g";
              };
              type = "button";
              val = "  Git Summary     ";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[e ~/Documents/Notes/scratch.md]] end";
              };
              opts = {
                position = "center";
                shortcut = "s";
              };
              type = "button";
              val = "  Scratchpad       ";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[e ~/nix-config/flake.nix]] end";
              };
              opts = {
                position = "center";
                shortcut = "c";
              };
              type = "button";
              val = "   Nix Config Flake";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[checkhealth]] end";
              };
              opts = {
                position = "center";
                shortcut = "c";
              };
              type = "button";
              val = "   Check health    ";
            }
            {
              on_press = {
                __raw = "function() vim.cmd[[qa]] end";
              };
              opts = {
                position = "center";
                shortcut = "q";
              };
              type = "button";
              val = " 󰅙  Quit nvim       ";
            }
          ];
        }
      ];
    };
  };
}