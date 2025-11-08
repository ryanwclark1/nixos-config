{
  pkgs,
  ...
}:

{
  # programs.walker = {
  #   enable = true;
  #   package = pkgs.walker;
  #   systemd.enable = true;
  # };
  home.packages = [ pkgs.walker ];

  # Walker configuration
  home.file.".config.walker/config.toml" = {
    force = true;
    text = ''
    close_when_open = true
    theme = "catppuccin"
    hotreload_theme = true
    force_keyboard_focus = true
    timeout = 60

    [keys.ai]
    run_last_response = ["ctrl e"]

    [list]
    max_entries = 200
    cycle = true

    [search]
    placeholder = " Search..."

    [builtins.hyprland_keybinds]
    path = "~/.config/hypr/hyprland.conf"
    hidden = true

    [builtins.applications]
    launch_prefix = "uwsm app -- "
    placeholder = " Search..."
    prioritize_new = false
    context_aware = false
    show_sub_when_single = false
    history = false
    icon = ""
    hidden = true

    [builtins.applications.actions]
    enabled = false
    hide_category = true

    [builtins.bookmarks]
    hidden = true

    [builtins.calc]
    name = "Calculator"
    icon = ""
    min_chars = 3
    prefix = "="

    [builtins.windows]
    switcher_only = true
    hidden = true

    [builtins.clipboard]
    hidden = true

    [builtins.commands]
    hidden = true

    [builtins.custom_commands]
    hidden = true

    [builtins.emojis]
    name = "Emojis"
    icon = ""
    prefix = ":"

    [builtins.symbols]
    after_copy = ""
    hidden = true

    [builtins.finder]
    use_fd = true
    cmd_alt = "xdg-open $(dirname ~/%RESULT%)"
    icon = "file"
    name = "Finder"
    preview_images = true
    hidden = false
    prefix = "."

    [builtins.runner]
    shell_config = ""
    switcher_only = true
    hidden = true

    [builtins.ssh]
    hidden = true

    [builtins.websearch]
    switcher_only = true
    hidden = true

    [builtins.translation]
    hidden = true
    '';
  };

  # Catppuccin theme files
  home.file.".config.walker/themes/catppuccin.css" = {
    force = true;
    text = ''
      @define-color rosewater #f2d5cf;
      @define-color flamingo #eebebe;
      @define-color pink #f4b8e4;
      @define-color mauve #ca9ee6;
      @define-color red #e78284;
      @define-color maroon #ea999c;
      @define-color peach #ef9f76;
      @define-color yellow #e5c890;
      @define-color green #a6d189;
      @define-color teal #81c8be;
      @define-color sky #99d1db;
      @define-color sapphire #85c1dc;
      @define-color blue #8caaee;
      @define-color lavender #babbf1;
      @define-color text #c6d0f5;
      @define-color subtext1 #b5bfe2;
      @define-color subtext0 #a5adce;
      @define-color overlay2 #949cbb;
      @define-color overlay1 #838ba7;
      @define-color overlay0 #737994;
      @define-color surface2 #626880;
      @define-color surface1 #51576d;
      @define-color surface0 #414559;
      @define-color base #303446;
      @define-color mantle #292c3c;
      @define-color crust #232634;

      #window,
      #box,
      #aiScroll,
      #aiList,
      #search,
      #password,
      #input,
      #prompt,
      #clear,
      #typeahead,
      #list,
      child,
      scrollbar,
      slider,
      #item,
      #text,
      #label,
      #bar,
      #sub,
      #activationlabel {
        all: unset;
      }

      #cfgerr {
        background: @red;
        margin-top: 20px;
        padding: 8px;
        font-size: 1.2em;
      }

      #window {
        color: @text;
      }

      #box {
        border-radius: 2px;
        background: @base;
        padding: 32px;
        border: 1px solid @crust;
      }

      #search {
        background: @mantle;
        padding: 8px;
      }

      #prompt {
        margin-left: 4px;
        margin-right: 12px;
        color: @text;
        opacity: 0.2;
      }

      #clear {
        color: @text;
        opacity: 0.8;
      }

      #password,
      #input,
      #typeahead {
        border-radius: 2px;
      }

      #input {
        background: none;
      }

      #password {
      }

      #spinner {
        padding: 8px;
      }

      #typeahead {
        color: @text;
        opacity: 0.8;
      }

      #input placeholder {
        opacity: 0.5;
      }

      #list {
      }

      child {
        padding: 8px;
        border-radius: 2px;
      }

      child:selected,
      child:hover {
        background: alpha(@surface0, 0.4);
      }

      #item {
      }

      #icon {
        margin-right: 8px;
      }

      #text {
        color: @text;
      }

      #label {
        font-weight: 500;
      }

      #sub {
        opacity: 0.5;
        font-size: 0.8em;
      }

      #activationlabel {
      }

      #bar {
      }

      .barentry {
      }

      .activation #activationlabel {
      }

      .activation #text,
      .activation #icon,
      .activation #search {
        opacity: 0.5;
      }

      .aiItem {
        padding: 10px;
        border-radius: 2px;
        color: @text;
        background: @base;
      }

      .aiItem.user {
        padding-left: 0;
        padding-right: 0;
      }

      .aiItem.assistant {
        background: @mantle;
      }
    '';
  };

  home.file.".config.walker/themes/catppuccin.toml" =
  {
    force = true;
    text = ''
    [ui.anchors]
    bottom = true
    left = true
    right = true
    top = true

    [ui.window]
    h_align = "fill"
    v_align = "fill"

    [ui.window.box]
    h_align = "center"
    width = 450

    [ui.window.box.bar]
    orientation = "horizontal"
    position = "end"

    [ui.window.box.bar.entry]
    h_align = "fill"
    h_expand = true

    [ui.window.box.bar.entry.icon]
    h_align = "center"
    h_expand = true
    pixel_size = 24
    theme = ""

    [ui.window.box.margins]
    top = 200

    [ui.window.box.ai_scroll]
    name = "aiScroll"
    h_align = "fill"
    v_align = "fill"
    max_height = 300
    min_width = 400
    height = 300
    width = 400

    [ui.window.box.ai_scroll.margins]
    top = 8

    [ui.window.box.ai_scroll.list]
    name = "aiList"
    orientation = "vertical"
    width = 400
    spacing = 10

    [ui.window.box.ai_scroll.list.item]
    name = "aiItem"
    h_align = "fill"
    v_align = "fill"
    x_align = 0
    y_align = 0
    wrap = true

    [ui.window.box.scroll.list]
    marker_color = "#1BFFE1"
    max_height = 300
    max_width = 400
    min_width = 400
    width = 400

    [ui.window.box.scroll.list.item.activation_label]
    h_align = "fill"
    v_align = "fill"
    width = 20
    x_align = 0.5
    y_align = 0.5

    [ui.window.box.scroll.list.item.icon]
    pixel_size = 26
    theme = ""

    [ui.window.box.scroll.list.margins]
    top = 8

    [ui.window.box.search.prompt]
    name = "prompt"
    icon = "edit-find"
    theme = ""
    pixel_size = 18
    h_align = "center"
    v_align = "center"

    [ui.window.box.search.clear]
    name = "clear"
    icon = "edit-clear"
    theme = ""
    pixel_size = 18
    h_align = "center"
    v_align = "center"

    [ui.window.box.search.input]
    h_align = "fill"
    h_expand = true
    icons = true

    [ui.window.box.search.spinner]
    hide = true
    '';
  };
}

