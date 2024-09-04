# TODO: Error executing Lua callback: /nix/store/wx63jbhbmsccs6ksh8x5fqgza6lmn1vv-init.lua:251: attempt to call global 'rndname' (a nil value)
# homepage: https://github.com/akinsho/toggleterm.nvim
# nixvim doc: https://nix-community.github.io/nixvim/plugins/toggleterm/index.html

_: {
  programs.nixvim.plugins.toggleterm = {
    enable = true;
    settings = {
      direction = "float";
      float_opts = {
        border = "rounded";
      };
      shadding_factor = 2;
      size = 10;

      highlights = {
        Normal.link = "Normal";
        NormalNC.link = "NormalNC";
        NormalFloat.link = "NormalFloat";
        FloatBorder.link = "FloatBorder";
        StatusLine.link = "StatusLine";
        StatusLineNC.link = "StatusLineNC";
        WinBar.link = "WinBar";
        WinBarNC.link = "WinBarNC";
      };

      # https://github.com/AstroNvim/AstroNvim/blob/v4.7.7/lua/astronvim/plugins/toggleterm.lua#L66-L74
      on_create = ''
        function(t)
          vim.opt_local.foldcolumn = "0"
          vim.opt_local.signcolumn = "no"
          if t.hidden then
            vim.keymap.set({ "n", "t", "i" }, "<F7>", function() t:toggle() end, { desc = "Toggle terminal", buffer = t.bufnr })
          end
          local term_name = rndname()
          vim.cmd(t.id .. "ToggleTermSetName " .. term_name)
        end
      '';
    };
  };
  programs.nixvim.keymaps = [
    # {
    #   mode = "n";
    #   key = "<leader>t";
    #   action = "<cmd>ToggleTerm<cr>";
    #   options = {
    #     desc = "Toggle Terminal Window";
    #   };
    # }
    {
      mode = "n";
      key = "<leader>tv";
      action = "<cmd>ToggleTerm direction=vertical<cr>";
      options = {
        desc = "Toggle Vertical Terminal Window";
      };
    }
    {
      mode = "n";
      key = "<leader>th";
      action = "<cmd>ToggleTerm direction=horizontal<cr>";
      options = {
        desc = "Toggle Horizontal Terminal Window";
      };
    }
    {
      mode = "n";
      key = "<leader>tf";
      action = "<cmd>ToggleTerm direction=float<cr>";
      options = {
        desc = "Toggle Floating Terminal Window";
      };
    }
    {
      mode = "n";
      key = "<F7>";
      action = "<Cmd>execute v:count . 'ToggleTerm'<CR>";
      options.desc = "Toggle terminal";
    }
    {
      mode = "t";
      key = "<F7>";
      action = "<Cmd>ToggleTerm<CR>";
      options.desc = "Toggle terminal";
    }
    {
      mode = "i";
      key = "<F7>";
      action = "<Esc><Cmd>ToggleTerm<CR>";
      options.desc = "Toggle terminal";
    }
    {
      mode = "t";
      key = "<Esc><Esc>";
      action = "<C-\\><C-n>";
      options.desc = "Switch to normal mode";
    }
    {
      mode = [ "n" "t" ];
      key = "<Leader>tn";
      action.__raw = ''
        function()
          local curterm = require("toggleterm.terminal").get_focused_id()

          if curterm ~= nil then
            vim.cmd(curterm .. "ToggleTermSetName")
          end
        end
      '';
      options.desc = "Rename current terminal";
    }
    {
      mode = [ "n" "t" ];
      key = "<Leader>tl";
      action = "<cmd>TermSelect<cr>";
      options.desc = "List terminals";
    }
  ];
}
