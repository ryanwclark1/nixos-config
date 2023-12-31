---@diagnostic disable, 113: unused-local, 113
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

ls.add_snippets("lua", {
  s("lf", {
    t("local "),
    i(1, "name"),
    t(" = function("),
    i(2, "parameter"),
    t({ ")", "  " }),
    i(3, "body"),
    t({ "", "end" }),
  }),
})

ls.add_snippets("nix", {
  s(
    "nmod",
    fmt(
      [[
{{
  pkgs,
  lib,
  config,
  ...
}}:
with lib;{{
  options.{}.enable = mkEnableOption "{} settings";
  config = mkIf config.{}.enable {{
    {}
  }};
}}
]],
      { i(1, "name"), rep(1), rep(1), i({ 4, "body" }) }
    )
  ),
})

ls.add_snippets("nix", {
  s(
    "hp",
    fmt(
      [[
home.packages = with pkgs; [
  {}
];
]],
      { i(1, "package") }
    )
  ),
})

ls.add_snippets("nix", {
  s(
    "pe",
    fmt(
      [[
programs.{} = {{
  enable = true;
}};
]],
      { i(1, "name") }
    )
  ),
})

ls.add_snippets("nix", {
  s(
    "se",
    fmt(
      [[
services.{} = {{
  enable = true;
}};
]],
      { i(1, "name") }
    )
  ),
})

ls.add_snippets("rust", {
  s(
    "tmod",
    fmt(
      [[
      #[cfg(test)]
      mod test {{
      {}

        {}
      }}

    ]],
      {
        c(1, { t("  use super::*;"), t("") }),
        i(0),
      }
    )
  ),
})

-- <c-k> is my expansion key
-- this will expand the current item or jump to the next item within the snippet.
vim.keymap.set({ "i", "s" }, "<c-k>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true })

-- <c-j> is my jump backwards key.
-- this always moves to the previous item within the snippet
vim.keymap.set({ "i", "s" }, "<c-j>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })

-- <c-l> is selecting within a list of options.
-- This is useful for choice nodes (introduced in the forthcoming episode 2)
vim.keymap.set("i", "<c-l>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)

vim.keymap.set("i", "<c-u>", require("luasnip.extras.select_choice"))
