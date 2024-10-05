-- require("full-border"):setup {
-- 	type = ui.Border.ROUNDED,
-- }

-- require("starship"):setup{}
require("folder-rules"):setup{}

-- Show symlink in status bar
function Status:name()
  local h = self._tab.current.hovered
  if not h then
    return ui.Line {}
  end

  local linked = ""
  if h.link_to ~= nil then
    linked = " -> " .. tostring(h.link_to)
  end
  return ui.Line(" " .. h.name .. linked)
end

local catppuccin_theme = require("yatline-catppuccin"):setup("mocha") -- or "latte" | "frappe" | "macchiato"

-- Yatline setup
require("yatline"):setup({
	section_separator = { open = "", close = "" },
	part_separator = { open = "", close = "" },
	inverse_separator = { open = "", close = "" },

	theme = catppuccin_theme,
	-- style_a = {
	-- 	fg = "black",
	-- 	bg_mode = {
	-- 		normal = "#a89984",
	-- 		select = "#d79921",
	-- 		un_set = "#d65d0e"
	-- 	}
	-- },
	-- style_b = { bg = "#665c54", fg = "#ebdbb2" },
	-- style_c = { bg = "#3c3836", fg = "#a89984" },

	permissions_t_fg = "green",
	permissions_r_fg = "yellow",
	permissions_w_fg = "red",
	permissions_x_fg = "cyan",
	permissions_s_fg = "darkgray",

	tab_width = 20,
	tab_use_inverse = false,

	selected = { icon = "󰻭", fg = "yellow" },
	copied = { icon = "", fg = "green" },
	cut = { icon = "", fg = "red" },

	total = { icon = "󰮍", fg = "yellow" },
	succ = { icon = "", fg = "green" },
	fail = { icon = "", fg = "red" },
	found = { icon = "󰮕", fg = "blue" },
	processed = { icon = "󰐍", fg = "green" },

	show_background = true,

	display_header_line = true,
	display_status_line = true,

	header_line = {
		left = {
			section_a = {
        			{type = "line", custom = false, name = "tabs", params = {"left"}},
			},
			section_b = {
			},
			section_c = {
			}
		},
		right = {
			section_a = {
        			{type = "string", custom = false, name = "date", params = {"%A, %d %B %Y"}},
			},
			section_b = {
        			{type = "string", custom = false, name = "date", params = {"%H:%M:%S"}},
			},
			section_c = {
				{type = "coloreds", custom = false, name = "githead"},
			}
		}
	},

	status_line = {
		left = {
			section_a = {
        			{type = "string", custom = false, name = "tab_mode"},
			},
			section_b = {
        			{type = "string", custom = false, name = "hovered_size"},
			},
			section_c = {
        			{type = "string", custom = false, name = "hovered_name"},
        			{type = "coloreds", custom = false, name = "count"},
			}
		},
		right = {
			section_a = {
        			{type = "string", custom = false, name = "cursor_position"},
			},
			section_b = {
        			{type = "string", custom = false, name = "cursor_percentage"},
			},
			section_c = {
        			{type = "string", custom = false, name = "hovered_file_extension", params = {true}},
        			{type = "coloreds", custom = false, name = "permissions"},
			}
		}
	},
})

require("yatline-githead"):setup({
	theme = catppuccin_theme,

	show_branch = true,
  branch_prefix = "on",
  branch_symbol = "",
  branch_borders = "()",

  commit_symbol = "@",

  show_behind_ahead = true,
  behind_symbol = "⇣",
  ahead_symbol = "⇡",

  show_stashes = true,
  stashes_symbol = "$",

  show_state = true,
  show_state_prefix = true,
  state_symbol = "~",

  show_staged = true,
  staged_symbol = "+",

  show_unstaged = true,
  unstaged_symbol = "!",

  show_untracked = true,
  untracked_symbol = "?",
})