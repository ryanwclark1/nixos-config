{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nil
    nixfmt
    biome
    taplo
    rust-analyzer
    gopls
    sourcekit-lsp
    kotlin-language-server
  ];

  programs.zed-editor = {
    enable = true;

    extensions = [
      "nix"
      "toml"
      "git-firefly"
      "docker-compose"
      "dockerfile"
      "env"
      "csv"
      "sql"
      "make"
      "html"
      "emmet"
      "tailwindcss"
      "ruff"
      "basher"
      "terraform"
      "helm"
      "swift"
      "kotlin"
    ];

    userSettings = {
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      ui_font_size = 16;
      buffer_font_size = 14;
      buffer_font_family = "FiraCode Nerd Font";
      buffer_font_features = {
        calt = true;
      };
      ui_font_family = "FiraCode Nerd Font";
      terminal = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 14;
        copy_on_select = true;
      };

      tab_size = 2;
      format_on_save = "on";
      soft_wrap = "editor_width";
      show_whitespaces = "all";
      ensure_final_newline_on_save = true;
      remove_trailing_whitespace_on_save = true;
      show_inline_completions = true;
      minimap = {
        show = "never";
      };
      indent_guides = {
        enabled = true;
        coloring = "indent_aware";
      };
      inlay_hints = {
        enabled = true;
      };
      scrollbar = {
        show = "auto";
        git_diff = true;
        search_results = true;
        diagnostics = true;
      };
      git = {
        inline_blame = {
          enabled = true;
        };
      };
      auto_update = false;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      languages = {
        Nix = {
          language_servers = [ "nil" ];
          formatter = {
            external = {
              command = "nixfmt";
            };
          };
          tab_size = 2;
        };
        Python = {
          tab_size = 4;
          formatter = {
            external = {
              command = "ruff";
              arguments = [ "format" "-" ];
            };
          };
        };
        JavaScript = {
          formatter = {
            external = {
              command = "biome";
              arguments = [ "format" "--stdin-file-path" "{buffer_path}" ];
            };
          };
        };
        TypeScript = {
          formatter = {
            external = {
              command = "biome";
              arguments = [ "format" "--stdin-file-path" "{buffer_path}" ];
            };
          };
        };
        TOML = {
          language_servers = [ "taplo" ];
        };
        Rust = {
          language_servers = [ "rust-analyzer" ];
          tab_size = 4;
        };
        Go = {
          language_servers = [ "gopls" ];
          tab_size = 4;
          formatter = "language_server";
        };
        Swift = {
          language_servers = [ "sourcekit-lsp" ];
          tab_size = 4;
        };
        Kotlin = {
          language_servers = [ "kotlin-language-server" ];
          tab_size = 4;
        };
      };

      # LLM providers (API keys stored in OS keychain, not here)
      language_models = {
        anthropic = {
          available_models = [
            {
              name = "claude-sonnet-4-20250514";
              display_name = "Claude Sonnet 4";
              max_tokens = 200000;
              max_output_tokens = 16384;
            }
            {
              name = "claude-opus-4-20250514";
              display_name = "Claude Opus 4";
              max_tokens = 200000;
              max_output_tokens = 32768;
            }
          ];
        };
        openai = { };
        google = { };
      };

      # Default model for agent panel
      assistant = {
        enabled = true;
        version = "2";
        default_model = {
          provider = "anthropic";
          model = "claude-sonnet-4-20250514";
        };
      };

      # Inline assistant model
      inline_assistant_model = {
        provider = "anthropic";
        model = "claude-sonnet-4-20250514";
      };

      # External agents (Claude Code, Codex, Gemini CLI)
      agent_servers = {
        claude-acp = {
          type = "registry";
        };
        codex-acp = {
          type = "registry";
        };
        gemini = {
          type = "registry";
        };
      };
    };

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "ctrl-shift-t" = "workspace::NewTerminal";
        };
      }
    ];
  };
}
