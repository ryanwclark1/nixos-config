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

    # Nushell-specific shell aliases (overrides common aliases that use && syntax)
    shellAliases = {
      nuconfig = "$EDITOR ~/.config/nushell/config.nu";
      reload = "exec nu";
      upgrade = lib.mkForce "nix flake update; sudo nixos-rebuild switch --flake .#$(hostname)";
      cleanup = lib.mkForce "sudo nix-collect-garbage -d; nix store optimise";
      "rust-update" = lib.mkForce "rustup update; cargo install-update -a";
      "rust-clean" = lib.mkForce "cargo clean; rm -rf ~/.cargo/registry/cache";
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

    extraConfig = ''
      def greet [] {
        let time = (date now | date format "%H:%M")
        let user = $env.USER
        let host = (sys | get host.hostname)
        echo $"Hello, ($user)! It's ($time) on ($host)"
      }

      def mkcd [dir: string] {
        mkdir $dir
        cd $dir
      }

      def gclone [repo: string] {
        let basename = ($repo | path parse | get stem)
        git clone $repo
        cd $basename
      }

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

      def backup [file: string] {
        let timestamp = (date now | date format "%Y%m%d_%H%M%S")
        cp -r $file $"($file).bak.($timestamp)"
      }

      def sysinfo [] {
        echo $"Hostname: (sys | get host.hostname)"
        echo $"Kernel: (sys | get host.kernel_version)"
        echo $"Uptime: (sys | get host.uptime)"
        echo $"Memory: (sys | get mem.used) / (sys | get mem.total)"
        echo $"CPU: (sys | get cpu | length) cores"
      }

      def weather [location?: string] {
        let loc = if ($location | is-empty) { "" } else { $location }
        http get $"https://wttr.in/($loc)?format=3"
      }

      def cheat [topic: string] {
        http get $"https://cheat.sh/($topic)"
      }

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

      if (which starship | complete).exit_code == 0 {
        if ("~/.cache/starship/init.nu" | path exists) {
          use ~/.cache/starship/init.nu
        }
      }
    '';

    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep) | append [
        "/usr/local/bin"
      ] | uniq)

      $env.BAT_STYLE = "numbers,changes,header"
      $env.EZA_COLORS = "uu=36:gu=37:sn=32:sb=32:da=34:ur=34:uw=35:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36"

      if ("/home/administrator/.env" | path exists) {
        open /home/administrator/.env | lines | each {|line|
          if ($line | str starts-with "#") {
            # Skip
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

    extraLogin = ''
      if (which fastfetch | complete).exit_code == 0 {
        fastfetch
      }
    '';

    plugins = with pkgs.nushellPlugins; [
      formats
      gstat
      query
    ];
  };

  home.file.".config/nushell/.keep".text = "";
}
