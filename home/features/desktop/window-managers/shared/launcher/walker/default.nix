{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  inherit (config.theme.colors)
    base00
    base01
    base02
    base05
    base08
    ;

  epkgs =
    if lib.hasAttr pkgs.stdenv.hostPlatform.system inputs.elephant.packages then
      inputs.elephant.packages.${pkgs.stdenv.hostPlatform.system}
    else
      { };
  elephantPkgNames = [
    "elephant"
    "elephant-calc"
    "elephant-clipboard"
    "elephant-bluetooth"
    "elephant-desktopapplications"
    "elephant-files"
    "elephant-menus"
    "elephant-providerlist"
    "elephant-runner"
    "elephant-symbols"
    "elephant-unicode"
    "elephant-websearch"
    "elephant-todo"
  ];
  elephantPkgs = builtins.concatLists (
    map (name: lib.optional (lib.hasAttr name epkgs) epkgs.${name}) elephantPkgNames
  );
in
{
  # programs.walker = {
  #   enable = true;
  #   package = pkgs.walker;
  #   systemd.enable = true;
  # };
  home.packages = [ pkgs.walker ] ++ elephantPkgs;

  # Ship Omarchy defaults for Walker/Elephant under .local/share so refresh scripts can deploy them
  home.file.".local/share/omarchy/config/walker/config.toml" = {
    force = true;
    text = builtins.readFile ./config.toml;
  };
  home.file.".local/share/omarchy/config/elephant/calc.toml" = {
    force = true;
    text = builtins.readFile ./elephant/calc.toml;
  };
  home.file.".local/share/omarchy/config/elephant/desktopapplications.toml" = {
    force = true;
    text = builtins.readFile ./elephant/desktopapplications.toml;
  };

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
      @define-color base00 #${base00};
      @define-color base01 #${base01};
      @define-color base02 #${base02};
      @define-color base05 #${base05};
      @define-color base08 #${base08};

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
        background: @base08;
        margin-top: 20px;
        padding: 8px;
        font-size: 1.2em;
      }

      #window {
        color: @base05;
      }

      #box {
        border-radius: 2px;
        background: @base00;
        padding: 32px;
        border: 1px solid @base01;
      }

      #search {
        background: @base01;
        padding: 8px;
      }

      #prompt {
        margin-left: 4px;
        margin-right: 12px;
        color: @base05;
        opacity: 0.2;
      }

      #clear {
        color: @base05;
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
        color: @base05;
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
        background: alpha(@base02, 0.4);
      }

      #item {
      }

      #icon {
        margin-right: 8px;
      }

      #text {
        color: @base05;
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
        color: @base05;
        background: @base00;
      }

      .aiItem.user {
        padding-left: 0;
        padding-right: 0;
      }

      .aiItem.assistant {
        background: @base01;
      }
    '';
  };

  home.file.".config.walker/themes/catppuccin.toml" = {
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
