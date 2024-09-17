_: {
  programs.nixvim.plugins.lualine = {
    enable = true;
    settings = {
      # globalstatus = true;
      extensions = [
        "fzf"
        "neo-tree"
      ];
      # disabledFiletypes = {
      #   statusline = ["startup" "alpha"];
      # };
      # theme = "catppuccin";
      options = {
        disabled_filetypes = {
          __unkeyed-1 = "startify";
          __unkeyed-2 = "neo-tree";
          statusline = [
            "dap-repl"
          ];
          winbar = [
            "aerial"
            "dap-repl"
            "neotest-summary"
          ];
        };
        globalstatus = true;
      };
      sections = {
        lualine_a = [
          "mode"
        ];
        lualine_b = [
          "branch"
          "diff"
        ];
        lualine_c = [
        "filename"
        "diff"
        ];
        lualine_x = [
          "diagnostics"
          {
            __unkeyed-1 = {
              __raw = ''
                function()
                    local msg = ""
                    local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                    local clients = vim.lsp.get_active_clients()
                    if next(clients) == nil then
                        return msg
                    end
                    for _, client in ipairs(clients) do
                        local filetypes = client.config.filetypes
                        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                            return client.name
                        end
                    end
                    return msg
                end
              '';
            };
            color = {
              fg = "#ffffff";
            };
            icon = "";
          }
          "encoding"
          "fileformat"
          "filetype"
        ];
        lualine_y = [
          {
            __unkeyed-1 = "aerial";
            colored = true;
            cond = {
              __raw = ''
                function()
                  local buf_size_limit = 1024 * 1024
                  if vim.api.nvim_buf_get_offset(0, vim.api.nvim_buf_line_count(0)) > buf_size_limit then
                    return false
                  end

                  return true
                end
              '';
            };
            dense = false;
            dense_sep = ".";
            depth = {
              __raw = "nil";
            };
            sep = " ) ";
          }
        ];
        lualine_z = [
          {
            __unkeyed-1 = "location";
          }
        ];
      };
      tabline = {
        lualine_a = [
          {
            __unkeyed-1 = "buffers";
            symbols = {
              alternate_file = "";
            };
          }
        ];
        lualine_z = [
          "tabs"
        ];
      };
      winbar = {
        lualine_c = [
          {
            __unkeyed-1 = "navic";
          }
        ];
        lualine_x = [
          {
            __unkeyed-1 = "filename";
            newfile_status = true;
            path = 3;
            shorting_target = 150;
          }
        ];
      };
    };
  };
}

#  {
#             name.__raw = ''
#               function()
#                 local icon = " "
#                 local status = require("copilot.api").status.data
#                 return icon .. (status.message or " ")
#               end,

#               cond = function()
#               local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
#               return ok and #clients > 0
#               end,
#             '';
#           }