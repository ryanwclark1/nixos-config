{config, ...}: {
  programs.helix.themes.veganMacchiato = {
    ###### UI
    inherits = "catppuccin_macchiato";
    # "ui.background" = {bg = config.colors.base.hex;};
    # "ui.background.separator" = {
    #   fg = config.colors.base.hex;
    #   modifiers = ["hidden"];
    # };
    "ui.cursor" = {
      modifiers = ["reversed" "slow_blink"];
    };

    "ui.cursor.primary" = {
      modifiers = ["reversed" "bold"];
    };

    "ui.cursor.match" = {
      modifiers = ["bold" "slow_blink"];
      bg = config.colors.macchiato.surface0.hex;
    };

    "ui.cursorline.primary" = {
      bg = config.colors.macchiato.mantle.hex;
    };
    "ui.cursorcolumn.primary" = {
      bg = config.colors.macchiato.mantle.hex;
    };
    "ui.menu" = {
      fg = config.colors.macchiato.text.hex;
      bg = config.colors.macchiato.crust.hex;
      modifiers = [];
    };
    "ui.menu.selected" = {
      fg = config.colors.macchiato.crust.hex;
      bg = config.colors.macchiato.sky.hex;
      modifiers = ["bold"];
    };
    "ui.linenr" = {
      fg = config.colors.macchiato.text.hex;
      bg = config.colors.macchiato.mantle.hex;
    };
    #
    "ui.gutter" = {
      bg = config.colors.macchiato.mantle.hex;
    };
    "ui.gutter.selected" = {
      fg = config.colors.macchiato.surface1.hex;
      bg = config.colors.macchiato.sky.hex;
      modifiers = ["bold"];
    };
    "ui.linenr.selected" = {
      fg = config.colors.macchiato.surface1.hex;
      bg = config.colors.macchiato.sky.hex;
      modifiers = ["bold"];
    };

    "ui.background" = {
      bg = config.colors.macchiato.base.hex;
    };
    "attribute" = {
      fg = config.colors.macchiato.peach.hex;
    };
    # "ui.statusline" = {
    #   fg = config.colors.subtle.hex;
    #   bg = config.colors.surface.hex;
    #   modifiers = ["bold"];
    # };
    # "ui.statusline.insert" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.love.hex;
    #   modifiers = ["bold"];
    # };
    # "ui.statusline.normal" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.foam.hex;
    #   modifiers = ["bold"];
    # };
    # "ui.statusline.select" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.iris.hex;
    #   modifiers = ["bold"];
    # };
    # "ui.statusline.inactive" = {
    #   fg = config.colors.iris.hex;
    #   bg = config.colors.surface.hex;
    # };
    # "ui.text" = {fg = config.colors.text.hex;};
    # "ui.text.focus" = {
    #   fg = config.colors.text.hex;
    #   modifiers = [];
    # };
    # "ui.text.info" = {
    #   fg = config.colors.text.hex;
    #   modifiers = [];
    # };
    "ui.bufferline" = {
      fg = config.colors.macchiato.subtext0.hex;
      bg = config.colors.macchiato.base.hex;
      modifiers = ["bold"];
    };
    "ui.bufferline.active" = {
      fg = config.colors.macchiato.base.hex;
      bg = config.colors.macchiato.pink.hex;
      modifiers = ["bold"];
    };

    "ui.bufferline.background" = {
      bg = config.colors.macchiato.mantle.hex;
    };
    #
    # # "ui.virtual.whitespace" = {bg = config.colors.love.hex;};
    # "ui.virtual.indent-guide" = {fg = config.colors.highlight-high.hex;};
    "ui.popup" = {bg = config.colors.macchiato.mantle.hex;};
    "ui.popup.info" = {bg = config.colors.macchiato.mantle.hex;};
    "ui.window" = {
      bg = config.colors.macchiato.mantle.hex;
      fg = config.colors.macchiato.surface1.hex;
      modifiers = ["hidden"];
    };
    "ui.help" = {
      bg = config.colors.macchiato.mantle.hex;
      fg = config.colors.macchiato.text.hex;
    };
    #
    # ##### tree-sitter
    #
    # "comment" = {
    # fg = config.colors.muted.hex;
    #   # bg = config.colors.pinebg.hex;
    #   modifiers = ["italic"];
    # };
    # "operator" = {
    #   fg = config.colors.text.hex;
    #   modifiers = ["bold"];
    # };
    # "punctuation" = {
    #   fg = config.colors.subtle.hex;
    #   modifiers = ["bold"];
    # };
    #
    # "punctuation.bracket" = {
    #   fg = config.colors.pine.hex;
    #   modifiers = ["bold"];
    # };
    # "variable" = config.colors.text.hex;
    # "constant" = config.colors.iris.hex;
    # "constant.numeric" = config.colors.iris.hex;
    # "constant.character.escape" = config.colors.subtle.hex;
    # "attributes" = config.colors.gold.hex;
    "type" = config.colors.macchiato.sky.hex;
    # "string" = {
    #   fg = config.colors.gold.hex;
    #   bg = config.colors.goldbg.hex;
    #   modifiers = ["italic"];
    # };
    "property" = config.colors.macchiato.flamingo.hex;
    #
    "function" = {
      fg = config.colors.macchiato.text.hex;
      modifiers = ["bold"];
    };
    "function.builtin" = config.colors.macchiato.maroon.hex;
    "function.method" = {
      fg = config.colors.macchiato.text.hex;
      modifiers = ["bold"];
    };

    "function.macro" = {
      fg = config.colors.macchiato.peach.hex;
      modifiers = ["bold"];
    };
    # "constructor" = config.colors.gold.hex;
    # "special" = config.colors.gold.hex;
    "keyword" = {
      fg = config.colors.macchiato.flamingo.hex;
      modifiers = ["bold"];
    };
    #
    "keyword.control" = {
      fg = config.colors.macchiato.teal.hex;
      modifiers = ["bold"];
    };
    #
    "keyword.function" = {
      fg = config.colors.macchiato.red.hex;
      modifiers = ["bold" "italic"];
    };
    #
    # "keyword.storage" = {
    #   fg = config.colors.rose.hex;
    #   modifiers = ["bold" "italic"];
    # };
    #
    # "label" = config.colors.iris.hex;
    #
    "namespace" = config.colors.macchiato.subtext0.hex;
    # "tag" = config.colors.foam.hex;
    # "text" = config.colors.text.hex;
    #
    # "diff.plus" = config.colors.foam.hex;
    # "diff.delta" = config.colors.rose.hex;
    # "diff.minus" = config.colors.love.hex;
    #
    # # gutter:
    # "info" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.pine.hex;
    # };
    # "hint" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.foam.hex;
    # };
    # "warning" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.gold.hex;
    # };
    # "error" = {
    #   fg = config.colors.base.hex;
    #   bg = config.colors.love.hex;
    # };
    # "debug" = config.colors.rose.hex;
    #
    # "diagnostic.hint" = {
    #   # fg = config.colors.pine.hex;
    #   modifiers = ["underlined"];
    #   underline = {
    #     style = "curl";
    #     color = config.colors.pine.hex;
    #   };
    # };
    # "diagnostic.info" = {
    #   # bg = config.colors.highlight-high.hex;
    #   modifiers = ["underlined"];
    #   underline = {
    #     style = "curl";
    #     color = config.colors.pine.hex;
    #   };
    # };
    # "diagnostic.warning" = {
    #   #fg = config.colors.gold.hex;
    #   # bg = config.colors.highlight-high.hex;
    #   modifiers = ["underlined"];
    #   underline = {
    #     style = "curl";
    #     color = config.colors.gold.hex;
    #   };
    # };
    # "diagnostic.error" = {
    #   # bg = config.colors.highlight-high.hex;
    #   modifiers = ["underlined"];
    #   underline = {
    #     style = "curl";
    #     color = config.colors.love.hex;
    #   };
    # };
    #
    "markup.heading.marker" = config.colors.macchiato.subtext0.hex;
    "markup.heading.1" = {
      bg = config.colors.macchiato.red.hex;
      fg = config.colors.macchiato.mantle.hex;
      modifiers = ["bold"];
    };

    "markup.heading.2" = {
      bg = config.colors.macchiato.maroon.hex;
      fg = config.colors.macchiato.mantle.hex;
      modifiers = ["bold"];
    };

    "markup.heading.3" = {
      bg = config.colors.macchiato.peach.hex;
      fg = config.colors.macchiato.mantle.hex;
      modifiers = ["bold"];
    };

    "markup.heading.4" = {
      bg = config.colors.macchiato.yellow.hex;
      fg = config.colors.macchiato.mantle.hex;
      modifiers = ["bold"];
    };

    "markup.heading.5" = {
      bg = config.colors.macchiato.green.hex;
      fg = config.colors.macchiato.mantle.hex;
      modifiers = ["bold"];
    };

    "markup.heading.6" = {
      bg = config.colors.macchiato.teal.hex;
      fg = config.colors.macchiato.mantle.hex;
      modifiers = ["bold"];
    };
    # "markup.list" = {fg = config.colors.love.hex;};
    # "markup.bold" = {
    #   fg = config.colors.gold.hex;
    #   modifiers = ["bold"];
    # };
    # "markup.italic" = {
    #   fg = config.colors.iris.hex;
    #   modifiers = ["italic"];
    # };
    # "markup.link.url" = {
    #   fg = config.colors.pine.hex;
    #   modifiers = ["underlined"];
    # };
    # "markup.link.text" = {fg = config.colors.foam.hex;};
    # "markup.quote" = {fg = config.colors.rose.hex;};
    # "markup.raw" = {fg = config.colors.foam.hex;};
  };
}