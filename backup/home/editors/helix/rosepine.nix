{config, ...}: {
  programs.helix.themes.rp = {
    ###### UI
    "ui.background" = {bg = config.colors.rosepine.base.hex;};
    "ui.background.separator" = {
      fg = config.colors.rosepine.base.hex;
      modifiers = ["hidden"];
    };
    "ui.cursor" = {
      modifiers = ["reversed" "slow_blink"];
    };

    "ui.cursor.primary" = {
      modifiers = ["reversed" "bold"];
    };

    "ui.cursor.match" = {
      # modifiers = ["reversed" "dim"];
      bg = config.colors.rosepine.foambg.hex;
    };

    "ui.cursorline.primary" = {
      bg = config.colors.rosepine.surface.hex;
    };
    "ui.cursorcolumn.primary" = {
      bg = config.colors.rosepine.surface.hex;
    };
    "ui.menu" = {
      fg = config.colors.rosepine.text.hex;
      bg = config.colors.rosepine.surface.hex;
      modifiers = [];
    };
    "ui.menu.selected" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.foam.hex;
      modifiers = ["bold"];
    };
    "ui.linenr" = {
      fg = config.colors.rosepine.muted.hex;
      bg = config.colors.rosepine.overlay.hex;
    };

    "ui.gutter" = {
      bg = config.colors.rosepine.overlay.hex;
    };
    "ui.gutter.selected" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.pine.hex;
      modifiers = ["bold"];
    };
    "ui.linenr.selected" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.pine.hex;
      modifiers = ["bold"];
    };
    "ui.selection" = {bg = config.colors.rosepine.lovebg.hex;};
    "ui.statusline" = {
      fg = config.colors.rosepine.subtle.hex;
      bg = config.colors.rosepine.surface.hex;
      modifiers = ["bold"];
    };
    "ui.statusline.insert" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.love.hex;
      modifiers = ["bold"];
    };
    "ui.statusline.normal" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.foam.hex;
      modifiers = ["bold"];
    };
    "ui.statusline.select" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.iris.hex;
      modifiers = ["bold"];
    };
    "ui.statusline.inactive" = {
      fg = config.colors.rosepine.iris.hex;
      bg = config.colors.rosepine.surface.hex;
    };
    "ui.text" = {fg = config.colors.rosepine.text.hex;};
    "ui.text.focus" = {
      fg = config.colors.rosepine.text.hex;
      modifiers = [];
    };
    "ui.text.info" = {
      fg = config.colors.rosepine.text.hex;
      modifiers = [];
    };
    "ui.bufferline" = {
      fg = config.colors.rosepine.muted.hex;
      bg = config.colors.rosepine.base.hex;
      modifiers = ["bold"];
    };
    "ui.bufferline.active" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.pine.hex;
      modifiers = ["bold"];
    };

    # "ui.virtual.whitespace" = {bg = config.colors.love.hex;};
    "ui.virtual.indent-guide" = {fg = config.colors.rosepine.highlight-high.hex;};
    "ui.popup" = {bg = config.colors.rosepine.surface.hex;};
    "ui.popup.info" = {bg = config.colors.rosepine.surface.hex;};
    "ui.window" = {
      bg = config.colors.rosepine.base.hex;
      fg = config.colors.rosepine.base.hex;
      modifiers = ["hidden"];
    };
    "ui.help" = {
      bg = config.colors.rosepine.surface.hex;
      fg = config.colors.rosepine.subtle.hex;
    };

    ##### tree-sitter

    "comment" = {
      fg = config.colors.rosepine.muted.hex;
      # bg = config.colors.pinebg.hex;
      modifiers = ["italic"];
    };
    "operator" = {
      fg = config.colors.rosepine.text.hex;
      modifiers = ["bold"];
    };
    "punctuation" = {
      fg = config.colors.rosepine.subtle.hex;
      modifiers = ["bold"];
    };

    "punctuation.bracket" = {
      fg = config.colors.rosepine.pine.hex;
      modifiers = ["bold"];
    };
    "variable" = config.colors.rosepine.text.hex;
    "constant" = config.colors.rosepine.iris.hex;
    "constant.numeric" = config.colors.rosepine.iris.hex;
    "constant.character.escape" = config.colors.rosepine.subtle.hex;
    "attributes" = config.colors.rosepine.gold.hex;
    "type" = config.colors.rosepine.foam.hex;
    "string" = {
      fg = config.colors.rosepine.gold.hex;
      bg = config.colors.rosepine.goldbg.hex;
      modifiers = ["italic"];
    };
    "property" = config.colors.rosepine.foam.hex;

    "function" = {
      fg = config.colors.rosepine.text.hex;
      modifiers = ["bold"];
    };
    "function.builtin" = config.colors.rosepine.rose.hex;
    "function.method" = config.colors.rosepine.text.hex;
    "constructor" = config.colors.rosepine.gold.hex;
    "special" = config.colors.rosepine.gold.hex;
    "keyword" = {
      fg = config.colors.rosepine.rose.hex;
      modifiers = ["bold"];
    };

    "keyword.control" = {
      fg = config.colors.rosepine.rose.hex;
      modifiers = ["bold"];
    };

    "keyword.function" = {
      fg = config.colors.rosepine.rose.hex;
      modifiers = ["bold" "italic"];
    };

    "keyword.storage" = {
      fg = config.colors.rosepine.rose.hex;
      modifiers = ["bold" "italic"];
    };

    "label" = config.colors.rosepine.iris.hex;

    "namespace" = config.colors.rosepine.muted.hex;
    "tag" = config.colors.rosepine.foam.hex;
    "text" = config.colors.rosepine.text.hex;

    "diff.plus" = config.colors.rosepine.foam.hex;
    "diff.delta" = config.colors.rosepine.rose.hex;
    "diff.minus" = config.colors.rosepine.love.hex;

    # gutter:
    "info" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.pine.hex;
    };
    "hint" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.foam.hex;
    };
    "warning" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.gold.hex;
    };
    "error" = {
      fg = config.colors.rosepine.base.hex;
      bg = config.colors.rosepine.love.hex;
    };
    "debug" = config.colors.rosepine.rose.hex;

    "diagnostic.hint" = {
      # fg = config.colors.pine.hex;
      modifiers = ["underlined"];
      underline = {
        style = "curl";
        color = config.colors.rosepine.pine.hex;
      };
    };
    "diagnostic.info" = {
      # bg = config.colors.highlight-high.hex;
      modifiers = ["underlined"];
      underline = {
        style = "curl";
        color = config.colors.rosepine.pine.hex;
      };
    };
    "diagnostic.warning" = {
      #fg = config.colors.gold.hex;
      # bg = config.colors.highlight-high.hex;
      modifiers = ["underlined"];
      underline = {
        style = "curl";
        color = config.colors.rosepine.gold.hex;
      };
    };
    "diagnostic.error" = {
      # bg = config.colors.highlight-high.hex;
      modifiers = ["underlined"];
      underline = {
        style = "curl";
        color = config.colors.rosepine.love.hex;
      };
    };

    "markup.heading.marker" = config.colors.rosepine.subtle.hex;
    "markup.heading.1" = {
      fg = config.colors.rosepine.love.hex;
      modifiers = ["bold"];
    };
    "markup.heading.2" = {
      fg = config.colors.rosepine.gold.hex;
      modifiers = ["bold"];
    };
    "markup.heading.3" = {
      fg = config.colors.rosepine.rose.hex;
      modifiers = ["bold"];
    };
    "markup.heading.4" = {
      fg = config.colors.rosepine.pine.hex;
      modifiers = ["bold"];
    };
    "markup.heading.5" = {
      fg = config.colors.rosepine.foam.hex;
      modifiers = ["bold"];
    };
    "markup.heading.6" = {
      fg = config.colors.rosepine.iris.hex;
      modifiers = ["bold"];
    };
    "markup.list" = {fg = config.colors.rosepine.love.hex;};
    "markup.bold" = {
      fg = config.colors.rosepine.gold.hex;
      modifiers = ["bold"];
    };
    "markup.italic" = {
      fg = config.colors.rosepine.iris.hex;
      modifiers = ["italic"];
    };
    "markup.link.url" = {
      fg = config.colors.rosepine.pine.hex;
      modifiers = ["underlined"];
    };

    "markup.link.text" = {fg = config.colors.rosepine.foam.hex;};
    "markup.quote" = {fg = config.colors.rosepine.rose.hex;};
    "markup.raw" = {fg = config.colors.rosepine.foam.hex;};
  };
}