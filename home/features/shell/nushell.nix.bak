{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;

    # Environment variables - comprehensive set matching ZSH
    environmentVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      LESS = "-R";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BROWSER = "firefox";
      TERM = "xterm-256color";
      BAT_THEME = "Catppuccin-frappe";
      
      # Development
      CARGO_HOME = "${config.home.homeDirectory}/.cargo";
      RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
      GOPATH = "${config.home.homeDirectory}/go";
      
      # XDG Base Directories
      XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
      XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
      XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
      XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    };

    # Shell aliases - comprehensive set matching ZSH configuration
    shellAliases = {
      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "-" = "cd -";
      
      # Git shortcuts
      g = "git";
      ga = "git add";
      gc = "git commit";
      gca = "git commit -a";
      gcam = "git commit -am";
      gco = "git checkout";
      gd = "git diff";
      gds = "git diff --staged";
      gl = "git log --oneline --graph";
      gp = "git push";
      gpu = "git pull";
      gs = "git status -sb";
      gst = "git status";
      
      # System management
      rebuild = "sudo nixos-rebuild switch --flake .#$(hostname)";
      update = "nix flake update";
      upgrade = "nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";
      cleanup = "sudo nix-collect-garbage -d && nix store optimise";
      
      # Better defaults
      grep = "rg";
      find = "fd";
      ps = "procs";
      top = "btop";
      htop = "btop";
      du = "dust";
      df = "duf";
      # cat alias handled by bat module
      # ls aliases handled by eza module
      la = "ls -a";  # Will use eza's ls alias
      ll = "ls -l";  # Will use eza's ls alias
      
      # Safety nets
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -I";
      
      # Shortcuts
      v = "nvim";
      vim = "nvim";
      vi = "nvim";
      e = "$EDITOR";
      o = "xdg-open";
      
      # Docker shortcuts
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      dimg = "docker images";
      drm = "docker rm";
      drmi = "docker rmi";
      
      # Systemctl shortcuts
      sc = "systemctl";
      scu = "systemctl --user";
      scs = "sudo systemctl";
      
      # Quick edits
      bashrc = "$EDITOR ~/.bashrc";
      zshrc = "$EDITOR ~/.zshrc";
      nuconfig = "$EDITOR ~/.config/nushell/config.nu";
      nixconf = "$EDITOR ~/nixos-config/flake.nix";
      
      # Network
      ip = "ip --color=auto";
      ports = "ss -tulanp";
      
      # Misc
      h = "history";
      help = "man";
      # j/jj aliases not needed - zoxide replaces cd directly
      mk = "mkdir -p";
      path = "echo $PATH | tr ':' '\\n'";
      reload = "exec nu";
      tf = "terraform";
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";
      
      # Kitty specific
      cik = "clone-in-kitty --type os-window";
      ck = "clone-in-kitty --type os-window";
    };

    # Nushell-specific settings
    settings = {
      show_banner = false;
      
      edit_mode = "vi";
      
      table = {
        mode = "rounded";
        index_mode = "always";
        header_on_separator = true;
      };
      
      history = {
        max_size = 100000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
      
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
        external = {
          enable = true;
          max_results = 100;
        };
      };
      
      filesize = {
        metric = true;
        format = "auto";
      };
      
      rm = {
        always_trash = true;
      };
    };

    # Extra configuration for config.nu
    extraConfig = ''
      # Custom functions matching ZSH/Bash features
      def greet [] {
        let time = (date now | date format "%H:%M")
        let user = $env.USER
        let host = (sys | get host.hostname)
        echo $"Hello, ($user)! It's ($time) on ($host)"
      }

      # Directory functions
      def mkcd [dir: string] {
        mkdir $dir
        cd $dir
      }

      # Git functions
      def gclone [repo: string] {
        let basename = ($repo | path parse | get stem)
        git clone $repo
        cd $basename
      }

      # Archive extraction
      def extract [file: string] {
        if ($file | path exists) {
          let ext = ($file | path parse | get extension)
          match $ext {
            "tar.bz2" => { tar xjf $file }
            "tar.gz" => { tar xzf $file }
            "bz2" => { bunzip2 $file }
            "rar" => { unrar e $file }
            "gz" => { gunzip $file }
            "tar" => { tar xf $file }
            "tbz2" => { tar xjf $file }
            "tgz" => { tar xzf $file }
            "zip" => { unzip $file }
            "Z" => { uncompress $file }
            "7z" => { 7z x $file }
            _ => { echo $"Cannot extract ($file)" }
          }
        } else {
          echo $"($file) is not a valid file"
        }
      }

      # Quick backup function
      def backup [file: string] {
        let timestamp = (date now | date format "%Y%m%d_%H%M%S")
        cp -r $file $"($file).bak.($timestamp)"
      }

      # System information
      def sysinfo [] {
        echo $"Hostname: (sys | get host.hostname)"
        echo $"Kernel: (sys | get host.kernel_version)"
        echo $"Uptime: (sys | get host.uptime)"
        echo $"Memory: (sys | get mem.used) / (sys | get mem.total)"
        echo $"CPU: (sys | get cpu | length) cores"
      }

      # Weather function
      def weather [location?: string] {
        let loc = if ($location | is-empty) { "" } else { $location }
        http get $"https://wttr.in/($loc)?format=3"
      }

      # Cheat sheet function
      def cheat [topic: string] {
        http get $"https://cheat.sh/($topic)"
      }

      # Zoxide integration handled by zoxide module with --cmd cd
      # The cd command is replaced by zoxide automatically

      # Git branch in prompt
      def git_branch [] {
        if (git rev-parse --git-dir | complete).exit_code == 0 {
          let branch = (git branch --show-current | str trim)
          if ($branch | is-empty) {
            "(detached)"
          } else {
            $branch
          }
        } else {
          ""
        }
      }

      # Custom prompt
      $env.PROMPT_COMMAND = {||
        let dir = (pwd | path parse | get stem)
        let branch = (git_branch)
        let branch_str = if ($branch | is-empty) { "" } else { $" \(($branch)\)" }
        $"(ansi green_bold)($dir)(ansi reset)($branch_str) "
      }

      $env.PROMPT_INDICATOR = {|| "> " }
      $env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
      $env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
      $env.PROMPT_MULTILINE_INDICATOR = {|| "... " }

      # Comprehensive keybindings matching other shells
      $env.config = ($env.config | upsert keybindings [
        {
          name: completion_menu
          modifier: control
          keycode: char_n
          mode: vi_insert
          event: {
            until: [
              { send: menu name: completion_menu }
              { send: menupagenext }
            ]
          }
        }
        {
          name: history_menu
          modifier: control
          keycode: char_r
          mode: vi_insert
          event: { send: menu name: history_menu }
        }
        {
          name: history_search_backward
          modifier: none
          keycode: up
          mode: [emacs vi_normal vi_insert]
          event: { send: historyhintcomplete }
        }
        {
          name: history_search_forward
          modifier: none
          keycode: down
          mode: [emacs vi_normal vi_insert]
          event: { send: historyhintcomplete }
        }
        {
          name: accept_suggestion
          modifier: control
          keycode: char_e
          mode: [emacs vi_insert]
          event: { send: historyhintcomplete }
        }
      ])

      # Load starship prompt if available
      if (which starship | complete).exit_code == 0 {
        use ~/.cache/starship/init.nu
      }
    '';

    # Extra environment configuration
    extraEnv = ''
      # Path configuration
      $env.PATH = ($env.PATH | split row (char esep) | append [
        $"($env.HOME)/.local/bin"
        $"($env.HOME)/.cargo/bin"
        $"($env.HOME)/go/bin"
        "/usr/local/bin"
      ] | uniq)

      # FZF configuration handled by fzf module

      # Bat configuration
      $env.BAT_THEME = "Catppuccin-frappe"
      $env.BAT_STYLE = "numbers,changes,header"

      # Eza configuration with better colors
      $env.EZA_COLORS = "uu=36:gu=37:sn=32:sb=32:da=34:ur=34:uw=35:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36"
      
      # LS_COLORS using vivid if available
      if (which vivid | complete | get exit_code) == 0 {
        $env.LS_COLORS = (vivid generate catppuccin-frappe)
      }

      # Load secrets if available
      if ("/home/administrator/.env" | path exists) {
        open /home/administrator/.env | lines | each {|line|
          if ($line | str starts-with "#") {
            # Skip comments
          } else if ($line | str contains "=") {
            let parts = ($line | split row "=" | str trim)
            if ($parts | length) >= 2 {
              let key = ($parts | get 0)
              let val = ($parts | skip 1 | str join "=")
              load-env { $key: $val }
            }
          }
        }
      }
    '';

    # Login configuration
    extraLogin = ''
      # Display system info on login (only in interactive sessions)
      if (which fastfetch | complete).exit_code == 0 {
        fastfetch
      }
    '';

    # Plugins configuration
    plugins = with pkgs.nushellPlugins; [
      formats
      gstat
      query
    ];
  };

  # Create necessary directories
  home.file.".config/nushell/.keep".text = "";
}