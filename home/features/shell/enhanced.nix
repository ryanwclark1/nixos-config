# Enhanced shell configuration with additional Home Manager options
{ config, lib, pkgs, ... }:

{
  # Additional Home Manager shell-related options
  
  # Set default shell (if you want to change from bash)
  # home.shell = pkgs.zsh;  # or pkgs.fish, pkgs.bash, etc.
  
  # Enable command-not-found handler
  programs.command-not-found = {
    enable = true;
    dbPath = "${pkgs.nix-index}/share/nix-index";
  };
  
  # Nix-index for command-not-found
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
  
  # History search with McFly (AI-powered shell history)
  programs.mcfly = {
    enable = false;  # Set to true to enable
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    keyScheme = "vim";  # or "emacs"
    fuzzySearchFactor = 2;  # 0 = exact match, higher = fuzzier
  };
  
  # Atuin - Enhanced shell history with sync
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = false;  # Set to true if you want cloud sync
      update_check = false;
      sync_frequency = "10m";
      search_mode = "fuzzy";
      style = "compact";
      inline_height = 10;
      show_preview = true;
      exit_mode = "return-original";
      filter_mode_shell_up_key_binding = "directory";
      
      # Key bindings
      keymap_mode = "auto";  # auto, vim-normal, vim-insert, emacs
      
      # UI settings
      show_help = true;
      show_tabs = true;
      invert = false;
    };
  };
  
  # Carapace - Multi-shell completion framework
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
  
  # Dircolors configuration
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    # Use vivid for LS_COLORS instead of settings here
    # settings = { ... };
  };
  
  # Readline configuration (for bash and other readline-based tools)
  programs.readline = {
    enable = true;
    bindings = {
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
      "\\C-p" = "history-search-backward";
      "\\C-n" = "history-search-forward";
      "\\e[C" = "forward-char";
      "\\e[D" = "backward-char";
      "\\C-a" = "beginning-of-line";
      "\\C-e" = "end-of-line";
      "\\C-k" = "kill-line";
      "\\C-u" = "unix-line-discard";
      "\\C-w" = "unix-word-rubout";
    };
    variables = {
      bell-style = "none";
      colored-completion-prefix = true;
      colored-stats = true;
      completion-ignore-case = true;
      completion-map-case = true;
      completion-prefix-display-length = 3;
      completion-query-items = 200;
      editing-mode = "emacs";  # or "vi"
      expand-tilde = true;
      history-preserve-point = true;
      history-size = 100000;
      horizontal-scroll-mode = false;
      mark-directories = true;
      mark-modified-lines = false;
      mark-symlinked-directories = true;
      match-hidden-files = true;
      menu-complete-display-prefix = true;
      page-completions = false;
      print-completions-horizontally = false;
      revert-all-at-newline = false;
      show-all-if-ambiguous = true;
      show-all-if-unmodified = true;
      show-mode-in-prompt = true;
      skip-completed-text = true;
      visible-stats = true;
    };
    extraConfig = ''
      # Include system-wide readline configuration if it exists
      $include /etc/inputrc
      
      # Additional custom configurations
      set enable-bracketed-paste on
    '';
  };
  
  # Pager configuration
  programs.lesspipe = {
    enable = true;
  };
  
  # Info reader configuration
  programs.info.enable = true;
  
  # Man pages configuration
  programs.man = {
    enable = true;
    generateCaches = false;  # Set to true if you want faster man page lookups
  };
  
  # Environment variables for better defaults
  home.sessionVariables = {
    # History control
    HISTCONTROL = lib.mkDefault "ignoreboth:erasedups";
    HISTTIMEFORMAT = lib.mkDefault "%F %T ";
    
    # Locale settings (if not set system-wide)
    # LANG = lib.mkDefault "en_US.UTF-8";
    # LC_ALL = lib.mkDefault "en_US.UTF-8";
    
    # Terminal
    COLORTERM = lib.mkDefault "truecolor";
    
    # FZF default options
    FZF_DEFAULT_OPTS = lib.mkDefault ''
      --height 40%
      --layout=reverse
      --border
      --inline-info
      --color=fg:#c6d0f5,bg:#303446,hl:#ca9ee6
      --color=fg+:#c6d0f5,bg+:#414559,hl+:#f4b8e4
      --color=info:#81c8be,prompt:#ef9f76,pointer:#f2d5cf
      --color=marker:#f2d5cf,spinner:#f4b8e4,header:#ca9ee6
    '';
    FZF_DEFAULT_COMMAND = lib.mkDefault "fd --type f --hidden --follow --exclude .git";
    FZF_CTRL_T_COMMAND = lib.mkDefault "$FZF_DEFAULT_COMMAND";
    FZF_ALT_C_COMMAND = lib.mkDefault "fd --type d --hidden --follow --exclude .git";
    
    # Ripgrep configuration file
    RIPGREP_CONFIG_PATH = lib.mkDefault "$HOME/.config/ripgrep/config";
    
    # GPG TTY for signing
    GPG_TTY = lib.mkDefault "$(tty)";
    
    # Python
    PYTHONDONTWRITEBYTECODE = lib.mkDefault "1";
    
    # Rust
    RUST_BACKTRACE = lib.mkDefault "1";
    
    # Go
    GOPATH = lib.mkDefault "$HOME/go";
    
    # Node.js
    NPM_CONFIG_PREFIX = lib.mkDefault "$HOME/.npm-global";
    
    # Docker
    DOCKER_BUILDKIT = lib.mkDefault "1";
    COMPOSE_DOCKER_CLI_BUILD = lib.mkDefault "1";
  };
  
  # Ripgrep configuration
  home.file.".config/ripgrep/config" = {
    text = ''
      # Ripgrep configuration file
      
      # Search hidden files by default
      --hidden
      
      # Follow symlinks
      --follow
      
      # Exclude directories
      --glob=!.git/
      --glob=!.svn/
      --glob=!node_modules/
      --glob=!.npm/
      --glob=!vendor/
      --glob=!target/
      --glob=!.cache/
      --glob=!.vscode/
      --glob=!.idea/
      --glob=!*.min.js
      --glob=!*.min.css
      
      # Set colors
      --colors=line:fg:yellow
      --colors=line:style:bold
      --colors=path:fg:green
      --colors=path:style:bold
      --colors=match:fg:red
      --colors=match:style:bold
      
      # Smart case search
      --smart-case
      
      # Use .gitignore files
      --no-ignore-parent
      
      # Max columns
      --max-columns=150
      
      # Add file types
      --type-add=nix:*.nix
      --type-add=vue:*.vue
      --type-add=scss:*.scss
    '';
  };
  
  # fd (find alternative) ignore file
  home.file.".fdignore" = {
    text = ''
      .git/
      .svn/
      node_modules/
      target/
      .cache/
      *.pyc
      __pycache__/
      .DS_Store
      Thumbs.db
    '';
  };
  
  # Global gitignore (useful for shell operations)
  home.file.".config/git/ignore" = {
    text = ''
      # OS generated files
      .DS_Store
      .DS_Store?
      ._*
      .Spotlight-V100
      .Trashes
      ehthumbs.db
      Thumbs.db
      
      # Editor directories and files
      .idea/
      .vscode/
      *.swp
      *.swo
      *~
      .netrwhist
      
      # Environment files
      .env
      .env.local
      .envrc
      
      # Build artifacts
      *.log
      npm-debug.log*
      yarn-debug.log*
      yarn-error.log*
      
      # Compiled files
      *.pyc
      __pycache__/
      *.class
      *.o
      *.so
      
      # Dependencies
      node_modules/
      vendor/
      
      # Personal notes
      .notes/
      TODO.md
    '';
  };
}