{
  plugins = {
    bufferline = {
      enable = true;
      settings = {
        options = {
          always_show_bufferline = true;
          auto_toggle_bufferline = true;
          buffer_close_icon = "󰅖";
          close_command = "bdelete! %d";
          close_icon = "";
          color_icons = true;
          custom_filter = ''
            function(buf_number, buf_numbers)
              -- filter out filetypes you don't want to see
              if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
                  return true
              end
              -- filter out by buffer name
              if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
                  return true
              end
              -- filter out based on arbitrary rules
              -- e.g. filter out vim wiki buffer from tabline in your work repo
              if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
                  return true
              end
              -- filter out by it's index number in list (don't show first buffer)
              if buf_numbers[1] ~= buf_number then
                  return true
              end
            end
          '';
          diagnostics = "nvim_lsp";
          diagnostics_indicator = ''
            function(count, level, diagnostics_dict, context)
              local s = ""
              for e, n in pairs(diagnostics_dict) do
                local sym = e == "error" and " "
                  or (e == "warning" and " " or "" )
                if(sym ~= "") then
                  s = s .. " " .. n .. sym
                end
              end
              return s
            end
          '';
          enforce_regular_tabs = false;
          get_element_icon = ''
            function(element)
              -- element consists of {filetype: string, path: string, extension: string, directory: string}
              -- This can be used to change how bufferline fetches the icon
              -- for an element e.g. a buffer or a tab.
              -- e.g.
              local icon, hl = require('nvim-web-devicons').get_icon_by_filetype(element.filetype, { default = false })
              return icon, hl
            end
          '';
          groups = {
            items = [
              {
                highlight = {
                  fg = "#a6da95";
                  sp = "#494d64";
                  underline = true;
                };
                matcher = {
                  __raw = ''
                    function(buf)
                      return buf.name:match('%test') or buf.name:match('%.spec')
                    end
                  '';
                };
                name = "Tests";
                priority = 2;
              }
              {
                auto_close = false;
                highlight = {
                  fg = "#ffffff";
                  sp = "#494d64";
                  undercurl = true;
                };
                matcher = {
                  __raw = ''
                    function(buf)
                      return buf.name:match('%.md') or buf.name:match('%.txt')
                    end
                  '';
                };
                name = "Docs";
              }
            ];
            options = {
              toggle_hidden_on_enter = true;
            };
          };
          hover = {
            enable = true;
            delay = 300;
          };
          indicator = {
            icon = "▎";
            style = "underline";
          };
          left_mouse_command = "buffer %d";
          left_trunc_marker = "";
          max_name_length = 18;
          max_prefix_length = 15;
          mode = "buffers";
          modified_icon = "●";
          move_wraps_at_ends = true;
          numbers = {
            __raw = ''
              function(opts)
                return string.format('%s·%s', opts.raise(opts.id), opts.lower(opts.ordinal))
              end
            '';
          };
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              highlight = "Directory";
              text_align = "center";
            }
          ];
          persist_buffer_sort = true;
          right_mouse_command = "bdelete! %d";
          right_trunc_marker = "";
          separator_style = [
            "|"
            "|"
          ];
          show_buffer_close_icons = true;
          show_buffer_icons = true;
          show_close_icon = true;
          show_duplicate_prefix = true;
          show_tab_indicators = true;
          sort_by = {
            __raw = ''
              function(buffer_a, buffer_b)
                  local modified_a = vim.fn.getftime(buffer_a.path)
                  local modified_b = vim.fn.getftime(buffer_b.path)
                  return modified_a > modified_b
              end
            '';
          };
          tab_size = 18;
          themable = true;
          truncate_names = true;
        };

        # NOTE: fixes colorscheme with transparent_background
        # and better contrast selected tabs
        # Todo fix commonBG and commonFG
        highlights =
          let
            commonBgColor = "#363a4f";
            commonFgColor = "#1e2030";

            commonSelectedAttrs = {
              bg = commonBgColor;
            };

            # Define a set with common selected attributes
            selectedAttrsSet = builtins.listToAttrs (
              map
                (name: {
                  inherit name;
                  value = commonSelectedAttrs;
                })
                [
                  # "separator_selected" # Handled uniquely
                  "buffer_selected"
                  "tab_selected"
                  "numbers_selected"
                  "close_button_selected"
                  "duplicate_selected"
                  "modified_selected"
                  "info_selected"
                  "warning_selected"
                  "error_selected"
                  "hint_selected"
                  "diagnostic_selected"
                  "info_diagnostic_selected"
                  "warning_diagnostic_selected"
                  "error_diagnostic_selected"
                  "hint_diagnostic_selected"
                ]
            );
          in
          # Merge the common selected attributes with the unique attributes
          selectedAttrsSet
          // {
            fill = {
              bg = commonFgColor;
            };
            separator = {
              fg = commonFgColor;
            };
            separator_visible = {
              fg = commonFgColor;
            };
            separator_selected = {
              bg = commonBgColor;
              fg = commonFgColor;
            };
          };

      };
    };
  };
  keymaps = [
    {
      mode = "n";
      key = "]b";
      action = "<cmd>BufferLineCycleNext<cr>";
      options = {
        desc = "Cycle to next buffer";
      };
    }

    {
      mode = "n";
      key = "[b";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options = {
        desc = "Cycle to previous buffer";
      };
    }

    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>BufferLineCycleNext<cr>";
      options = {
        desc = "Cycle to next buffer";
      };
    }

    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options = {
        desc = "Cycle to previous buffer";
      };
    }

    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<cr>";
      options = {
        desc = "Delete buffer";
      };
    }

    {
      mode = "n";
      key = "<leader>bl";
      action = "<cmd>BufferLineCloseLeft<cr>";
      options = {
        desc = "Delete buffers to the left";
      };
    }

    {
      mode = "n";
      key = "<leader>bo";
      action = "<cmd>BufferLineCloseOthers<cr>";
      options = {
        desc = "Delete other buffers";
      };
    }

    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>BufferLineTogglePin<cr>";
      options = {
        desc = "Toggle pin";
      };
    }

    {
      mode = "n";
      key = "<leader>bP";
      action = "<Cmd>BufferLineGroupClose ungrouped<CR>";
      options = {
        desc = "Delete non-pinned buffers";
      };
    }
  ];
  extraConfigLua = ''
    vim.opt.termguicolors = true
    require("bufferline").setup{}
  '';
}
