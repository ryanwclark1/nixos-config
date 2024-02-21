{
  config,
  ...
}:

let inherit (config.colorscheme) palette variant;
in
{

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "text/xml" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/qute" = [ "org.qutebrowser.qutebrowser.desktop" ];
  };


  programs.qutebrowser = {
    enable = true;
    loadAutoconfig = true;
    settings = {
      editor.command = [ "xdg-open" "{file}" ];
      tabs = {
        show = "multiple";
        position = "left";
      };
      fonts = {
        default_family = config.fontProfiles.regular.family;
        default_size = "12pt";
      };
      colors = {
        webpage = {
          preferred_color_scheme = variant;
          bg = "#ffffff";
        };
        completion = {
          fg = "#${palette.base05}";
          match.fg = "#${palette.base09}";
          even.bg = "#${palette.base00}";
          odd.bg = "#${palette.base00}";
          scrollbar = {
            bg = "#${palette.base00}";
            fg = "#${palette.base05}";
          };
          category = {
            bg = "#${palette.base00}";
            fg = "#${palette.base0D}";
            border = {
              bottom = "#${palette.base00}";
              top = "#${palette.base00}";
            };
          };
          item.selected = {
            bg = "#${palette.base02}";
            fg = "#${palette.base05}";
            match.fg = "#${palette.base05}";
            border = {
              bottom = "#${palette.base02}";
              top = "#${palette.base02}";
            };
          };
        };
        contextmenu = {
          disabled = {
            bg = "#${palette.base01}";
            fg = "#${palette.base04}";
          };
          menu = {
            bg = "#${palette.base00}";
            fg = "#${palette.base05}";
          };
          selected = {
            bg = "#${palette.base02}";
            fg = "#${palette.base05}";
          };
        };
        downloads = {
          bar.bg = "#${palette.base00}";
          error.fg = "#${palette.base08}";
          start = {
            bg = "#${palette.base0D}";
            fg = "#${palette.base00}";
          };
          stop = {
            bg = "#${palette.base0C}";
            fg = "#${palette.base00}";
          };
        };
        hints = {
          bg = "#${palette.base0A}";
          fg = "#${palette.base00}";
          match.fg = "#${palette.base05}";
        };
        keyhint = {
          bg = "#${palette.base00}";
          fg = "#${palette.base05}";
          suffix.fg = "#${palette.base05}";
        };
        messages = {
          error.bg = "#${palette.base08}";
          error.border = "#${palette.base08}";
          error.fg = "#${palette.base00}";
          info.bg = "#${palette.base00}";
          info.border = "#${palette.base00}";
          info.fg = "#${palette.base05}";
          warning.bg = "#${palette.base0E}";
          warning.border = "#${palette.base0E}";
          warning.fg = "#${palette.base00}";
        };
        prompts = {
          bg = "#${palette.base00}";
          fg = "#${palette.base05}";
          border = "#${palette.base00}";
          selected.bg = "#${palette.base02}";
        };
        statusbar = {
          caret.bg = "#${palette.base00}";
          caret.fg = "#${palette.base0D}";
          caret.selection.bg = "#${palette.base00}";
          caret.selection.fg = "#${palette.base0D}";
          command.bg = "#${palette.base01}";
          command.fg = "#${palette.base04}";
          command.private.bg = "#${palette.base01}";
          command.private.fg = "#${palette.base0E}";
          insert.bg = "#${palette.base00}";
          insert.fg = "#${palette.base0C}";
          normal.bg = "#${palette.base00}";
          normal.fg = "#${palette.base05}";
          passthrough.bg = "#${palette.base00}";
          passthrough.fg = "#${palette.base0A}";
          private.bg = "#${palette.base00}";
          private.fg = "#${palette.base0E}";
          progress.bg = "#${palette.base0D}";
          url.error.fg = "#${palette.base08}";
          url.fg = "#${palette.base05}";
          url.hover.fg = "#${palette.base09}";
          url.success.http.fg = "#${palette.base0B}";
          url.success.https.fg = "#${palette.base0B}";
          url.warn.fg = "#${palette.base0E}";
        };
        tabs = {
          bar.bg = "#${palette.base00}";
          even.bg = "#${palette.base00}";
          even.fg = "#${palette.base05}";
          indicator.error = "#${palette.base08}";
          indicator.start = "#${palette.base0D}";
          indicator.stop = "#${palette.base0C}";
          odd.bg = "#${palette.base00}";
          odd.fg = "#${palette.base05}";
          pinned.even.bg = "#${palette.base0B}";
          pinned.even.fg = "#${palette.base00}";
          pinned.odd.bg = "#${palette.base0B}";
          pinned.odd.fg = "#${palette.base00}";
          pinned.selected.even.bg = "#${palette.base02}";
          pinned.selected.even.fg = "#${palette.base05}";
          pinned.selected.odd.bg = "#${palette.base02}";
          pinned.selected.odd.fg = "#${palette.base05}";
          selected.even.bg = "#${palette.base02}";
          selected.even.fg = "#${palette.base05}";
          selected.odd.bg = "#${palette.base02}";
          selected.odd.fg = "#${palette.base05}";
        };
      };
    };
    extraConfig = ''
      c.tabs.padding = {"bottom": 10, "left": 10, "right": 10, "top": 10}
    '';
  };
}
