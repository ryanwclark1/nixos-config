{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  imports = [./rosepine.nix ./catppuccin-improved.nix];

  options.helix.enable = mkEnableOption "helix settings";

  config = mkIf config.helix.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;

      package = config.editor.helix.package;

      extraPackages = with pkgs; [
        nodePackages.bash-language-server
        nodePackages.dockerfile-language-server-nodejs
        nodePackages.vscode-langservers-extracted
        taplo-lsp
        yaml-language-server
        clang
        marksman
        # external.snippets-ls
        tailwindcss
        # tailwindcss-language-server
        lua-language-server
      ];

      languages = {
        language-server = {
          gopls = {
            command = "gopls";
            config = {
              hints = {
                assignVariableTypes = true;
                compositeLiteralFields = true;
                constantValues = true;
                functionTypeParameters = true;
                parameterNames = true;
                rangeVariableTypes = true;
              };
              gofumpt = true;

              staticcheck = false;

              analyses = {
                nilness = true;
                shadow = true;
                unusedwrite = true;
                unusedparams = true;
                useany = true;
                unusedvariable = true;
              };

              vulncheck = "Imports";
              semanticTokens = true;
            };
          };
          nil = {
            command = "nil";

            config.nil = {
              formatting.command = ["alejandra" "--quiet"];
              nix.flake = {
                # autoEvalInputs = true;
              };
            };
          };
          snippets-go = {
            command = "snippets-ls";
            args = ["-config" "/home/a/.config/helix/snippets-go.json"];
          };
          snippets-rust = {
            command = "snippets-ls";
            args = ["-config" "/home/a/.config/helix/snippets-rust.json"];
          };
          snippets-nix = {
            command = "snippets-ls";
            args = ["-config" "/home/a/.config/helix/snippets-nix.json"];
          };
          snippets-md = {
            command = "snippets-ls";
            args = ["-config" "/home/a/.config/helix/snippets-md.json"];
          };
          snippets-org = {
            command = "snippets-ls";
            args = ["-config" "/home/a/.config/helix/snippets-org.json"];
          };

          hls = mkIf config.haskell.enable {
            command = "haskell-language-server-wrapper";
            # args = ["--lsp"];
            config = {
              hling.config.flags = [
                "--all"
              ];
              rename.config.crossModule = true;
            };
          };
          rustanalyzer = {
            command = "rust-analyzer";
            config = {
              cargo.extraEnv = {CARGO_TARGET_DIR = "./target/rust_analyzer";};
              check.command = "clippy";
              rustc.source = "discover";
              inlayHints.bindingModeHints.enable = true;
              inlayHints.closingBraceHints.minLines = 10;
              inlayHints.closureReturnTypeHints.enable = "with_block";
              inlayHints.discriminantHints.enable = "fieldless";
              inlayHints.lifetimeElisionHints.enable = "skip_trivial";
              inlayHints.typeHints.hideClosureInitialization = false;
            };
          };
        };
        language = [
          {
            name = "haskell";
            roots = ["Setup.hs" "stack.yaml" "cabal.project" "*.cabal" "hie.yaml"];
            auto-format = true;
            language-servers = ["hls"];
          }
          {
            name = "ocaml";
            auto-format = true;
            formatter = {
              command = "ocamlformat";
              args = ["--impl" "-"];
              formatStdin = true;
            };
          }
          {
            name = "html";
            language-servers = ["vscode-html-language-server" "tailwindcss-ls"];
          }
          {
            name = "css";
            language-servers = ["vscode-css-language-server" "tailwindcss-ls"];
          }
          {
            name = "javascript";
            language-servers = ["typescript-language-server" "tailwindcss-ls"];
          }
          {
            name = "nix";
            auto-format = true;
            formatter = {
              command = "alejandra";
              args = ["--quiet"];
            };

            language-servers = ["nil" "snippets-nix"];
          }
          {
            name = "markdown";
            language-servers = ["snippets-md" "marksman"];
            soft-wrap = {
              enable = true;
            };
          }

          {
            name = "go";
            auto-format = true;
            formatter.command = "gofumpt";
            language-servers = ["gopls" "golangci-lint-lsp" "snippets-go"];
          }
          {
            name = "rust";
            language-servers = ["rustanalyzer" "snippets-rust"];
          }
        ];
      };

      settings = {
        theme = "veganMacchiato";
        editor = {
          shell = ["zsh" "-c"];
          # auto-format = true; # default is true

          # auto completion
          idle-timeout = 0;
          completion-trigger-len = 1;

          # ui
          line-number = "relative";
          color-modes = true;
          cursorline = true;
          cursorcolumn = true;
          bufferline = "always";
          indent-guides = {
            render = true;
            character = "┃";
          };

          cursor-shape = {
            insert = "bar";
            # normal = "block"; # default is block
            # select = "block"; # default is block
          };

          statusline = {
            left = ["mode" "spacer" "diagnostics"];
            center = ["file-name" "file-modification-indicator" "version-control"];
            right = ["workspace-diagnostics" "spacer" "spinner" "spacer" "position-percentage" "spacer" "total-line-numbers"];
          };

          # lsp
          lsp.display-messages = true;
          lsp.display-inlay-hints = true;
          lsp.display-signature-help-docs = false;

          # tools
          auto-pairs = true;
          file-picker.hidden = true;
          file-picker.git-ignore = true;
        };

        keys = {
          normal = {
            "S-right" = ":buffer-next";
            "S-left" = ":buffer-previous";
            "S-L" = ":buffer-next";
            "S-H" = ":buffer-previous";
            # ret = ["open_below" "normal_mode"];
            "C-f" = [":new" ":insert-output lf-pick" ":theme default" "select_all" "split_selection_on_newline" "goto_file" "goto_last_modified_file" ":buffer-close!" ":theme veganMacchiato"];
            X = ["extend_line_above"];
            space = {
              c = ":bc";
              R = [":primary-clipboard-paste-replace"];
            };
            # y = [":clipboard-yank-join"];
            # p = [":clipboard-paste-after"];
            # P = [":clipboard-paste-before"];
            # d = [":clipboard-yank-join" "delete_selection"];
            pageup = "no_op";
            pagedown = "no_op";
          };

          select = {
            "S-right" = ":buffer-next";
            "S-left" = ":buffer-previous";
            # y = [":clipboard-yank-join"];
            pageup = "no_op";
            pagedown = "no_op";
          };

          insert = {
            "S-right" = ":buffer-next";
            "S-left" = ":buffer-previous";
            up = "move_line_up";
            down = "move_line_down";
            left = "move_char_left";
            right = "move_char_right";
            pageup = "no_op";
            pagedown = "no_op";
          };
        };
      };
    };

    home.file = let
      snippets-go = pkgs.writeTextFile {
        name = "snippets-go.json";
        text = builtins.toJSON {
          "function declaration" = {
            "prefix" = "gf";
            "body" = "func $1($2) $3 {\n\t$0\n}";
            "description" = "Snippet for function declaration";
          };

          "better Err" = {
            "body" = "fmt.Errorf(\"$0: %w\", err)";
            "description" = "Snippet for wrapping error";
            "prefix" = "erf";
          };
          "new error" = {
            "body" = "var $0 error = errors.New(\"$1\")";
            "description" = "Snippet for wrapping error";
            "prefix" = "ern";
          };
        };
        destination = "";
      };
      snippets-rust = pkgs.writeTextFile {
        name = "snippets-rust.json";
        text = builtins.toJSON {
          "test module" = {
            body = "#[cfg(test)]\nmod testing{\n\t#[allow(clippy::wildcard_imports)]\n\tuse super::*;\n\t$0\n}";
            description = "Snippet for creating test modules";
            prefix = "tmod";
          };

          "Is Normal Test" = {
            body = "fn is_normal<T: Sized + Send + Sync + Unpin>() {}\n#[test]\nfn normal_types() {\n\tis_normal::<$0>();\n}";
            description = "Snippet for creating normal test";
            prefix = "tnorm";
          };
          "optionally derive serde" = {
            body = "#[cfg_attr(feature = \"serde\", derive(serde::Serialize, serde::Deserialize))]";
            description = "Snippet for optionally deriving serde";
            prefix = "drserde";
          };
          "usual struct derieves " = {
            body = "#[cfg_attr(feature = \"serde\", derive(serde::Serialize, serde::Deserialize))]\n#[derive(Clone, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]";
            description = "Snippet for optionally deriving serde";
            prefix = "drn";
          };
          "error enum derieves " = {
            body = "#[cfg_attr(feature = \"serde\", derive(serde::Serialize, serde::Deserialize))]\n#[derive(Clone, Debug, PartialEq, Eq, Hash, thiserror::Error)]";
            description = "Snippet for optionally deriving serde";
            prefix = "dre";
          };
        };
        destination = "";
      };
      snippets-nix = pkgs.writeTextFile {
        name = "snippets-nix.json";
        text = builtins.toJSON {
          "new module" = {
            body = "{\n\tpkgs,\n\tlib,\n\tconfig,\n\t...\n}:\nwith lib;{\n\toptions.$\{1:foo\}.enable = mkEnableOption \"$\{2:foo\} settings\";\n\tconfig = mkIf config.$\{3:foo\}.enable {\n\t$0\n\t};\n}";
            description = "Snippet for creating module";
            prefix = "nmod";
          };
          "new program" = {
            body = "programs.$\{0:foo\}={\n\tenable = true;\n};";
            description = "snippet for enabling program";
            prefix = "pe";
          };
          "new service" = {
            body = "services.$\{0:foo\}={\n\tenable = true;\n};";
            description = "snippet for enabling service";
            prefix = "se";
          };
        };
        destination = "";
      };
      snippets-md = pkgs.writeTextFile {
        name = "snippets-md.json";
        text = builtins.toJSON {
          "dfn" = {
            body = "{{<dfn `$\{1\}`>}}$\{0\}";
            description = "definitions";
            prefix = "dfn";
          };
          "lang" = {
            body = "{{<lang `$\{1\}`>}}$\{0\}";
            description = "languages";
            prefix = "lang";
          };
          "abbr" = {
            body = "{{<abbr `$\{1\}`>}}$\{0\}";
            description = "abbreviation";
            prefix = "abbr";
          };
        };
        destination = "";
      };
      snippets-org = pkgs.writeTextFile {
        name = "snippets-org.json";
        text =
          builtins.toJSON {
          };
        destination = "";
      };
    in {
      ".config/helix/snippets-go.json" = {
        source = snippets-go;
      };
      ".config/helix/snippets-rust.json" = {
        source = snippets-rust;
      };
      ".config/helix/snippets-nix.json" = {
        source = snippets-nix;
      };
      ".config/helix/snippets-md.json" = {
        source = snippets-md;
      };
      ".config/helix/snippets-org.json" = {
        source = snippets-org;
      };
    };
    # home.packages = with pkgs; [
    #   nodePackages.bash-language-server
    #   nodePackages.dockerfile-language-server-nodejs
    #   nodePackages.vscode-langservers-extracted
    #   taplo-lsp
    #   yaml-language-server
    #   clang
    #   marksman
    #   external.snippets-ls

    #   # gcc
    # ];
  };
}