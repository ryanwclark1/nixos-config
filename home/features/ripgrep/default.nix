{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Basic ripgrep configuration
  programs.ripgrep = {
    enable = true;
    package = pkgs.ripgrep;

    arguments = [
      # Search options
      "--smart-case"
      "--follow"
      "--hidden"
      "--max-columns=150"
      "--max-columns-preview"

      # Exclude patterns
      "--glob=!.git/*"
      "--glob=!node_modules/*"
      "--glob=!dist/*"
      "--glob=!build/*"
      "--glob=!target/*"
      "--glob=!.venv/*"
      "--glob=!venv/*"
      "--glob=!.next/*"
      "--glob=!.nuxt/*"
      "--glob=!/proc"
      "--glob=!/sys"
      "--glob=!*.min.js"
      "--glob=!*.map"

      # Performance
      "--threads=0"
      "--max-filesize=50M"

      # Type additions
      "--type-add=nix:*.nix"
      "--type-add=web:*.{html,css,js,jsx,ts,tsx,vue,svelte}*"
      "--type-add=config:*.{json,toml,yaml,yml,ini,conf,cfg}"
      "--type-add=docker:Dockerfile*,docker-compose*.{yml,yaml}"
      "--type-add=terraform:*.{tf,tfvars}"
      "--type-add=ansible:*.{yml,yaml}"
    ];
  };

  # Ripgrep-all for searching in PDFs, Office docs, archives, etc.
  programs.ripgrep-all = {
    enable = true;
    package = pkgs.ripgrep-all;

    custom_adapters = [
      # Enhanced PDF adapter with OCR support
      {
        name = "pdf-enhanced";
        description = "PDF text extraction with fallback to OCR";
        extensions = [ "pdf" ];
        command = "${pkgs.poppler_utils}/bin/pdftotext";
        args = [ "-layout" "-nopgbrk" "-" "-" ];
        binary = false;
      }

      # Jupyter notebook content extraction
      {
        name = "jupyter";
        description = "Extract code and markdown from Jupyter notebooks";
        extensions = [ "ipynb" ];
        command = "${pkgs.jq}/bin/jq";
        args = [
          "-r"
          ".cells[] | select(.source != null) | .source | if type == \"array\" then .[] else . end"
        ];
        binary = false;
      }

      # SQLite database content
      {
        name = "sqlite";
        description = "Dump SQLite database schema and data";
        extensions = [ "db" "sqlite" "sqlite3" ];
        command = "${pkgs.sqlite}/bin/sqlite3";
        args = [ "-readonly" "-" ".schema" ".dump" ];
        binary = true;
      }

      # Extract strings from binary files
      {
        name = "binary";
        description = "Extract readable strings from binary files";
        extensions = [ "exe" "dll" "so" "dylib" "bin" ];
        command = "${pkgs.binutils}/bin/strings";
        args = [ "-a" "-n" "8" "-" ];
        binary = true;
      }

      # Archive contents listing
      {
        name = "archive";
        description = "List contents of compressed archives";
        extensions = [ "tar" "gz" "bz2" "xz" "zip" "7z" ];
        command = "${pkgs.atool}/bin/atool";
        args = [ "-l" "-q" "-" ];
        binary = true;
      }

      # EXIF data from images
      {
        name = "image-meta";
        description = "Extract metadata from image files";
        extensions = [ "jpg" "jpeg" "png" "gif" "bmp" "tiff" "webp" "heic" ];
        command = "${pkgs.exiftool}/bin/exiftool";
        args = [ "-All" "-" ];
        binary = true;
      }

      # Markdown code block extraction
      {
        name = "markdown";
        description = "Extract code blocks from markdown";
        extensions = [ "md" "mdx" ];
        command = "${pkgs.gawk}/bin/awk";
        args = [
          "/^```/,/^```/ { print }"
          "-"
        ];
        binary = false;
      }

      # Log file filtering
      {
        name = "logs";
        description = "Extract errors and warnings from logs";
        extensions = [ "log" ];
        command = "${pkgs.gnugrep}/bin/grep";
        args = [
          "-E"
          "(ERROR|WARN|FAIL|CRITICAL|Exception|Traceback|panic|fatal)"
          "-C" "3"
        ];
        binary = false;
      }
    ];
  };

  # Additional search tools
  home.packages = with pkgs; [
    sd              # Modern find & replace (better sed)
    repgrep         # Ripgrep with replacement support
    fselect         # Find files with SQL-like queries
    fd              # Modern find replacement
    # silver-searcher  # ag - another fast searcher
  ];

  # Shell aliases for convenience
  home.shellAliases = {
    # Ripgrep shortcuts
    rg = "rg --smart-case";
    rgf = "rg --files";
    rgi = "rg -i";
    rgl = "rg -l";
    rgc = "rg -c";
    rgn = "rg --no-heading --line-number";

    # Ripgrep-all shortcuts
    rga = "rga --smart-case";
    rgai = "rga -i";
    rgal = "rga -l";
    rgap = "rga --rga-adapters=+pdf-enhanced,jupyter,sqlite";

    # Search with specific types
    rgnix = "rg --type nix";
    rgweb = "rg --type web";
    rgconf = "rg --type config";
    rgdocker = "rg --type docker";
  };

  # Environment variables handled by Home Manager's ripgrep module

  # Ripgrep configuration file (using Home Manager's expected name)
  # home.file.".config/ripgrep/ripgreprc" = {
  #   text = ''
  #     # Default search behavior
  #     --smart-case
  #     --hidden
  #     --follow

  #     # Output formatting
  #     --max-columns=150
  #     --max-columns-preview
  #     --line-number
  #     --heading
  #     --color=auto

  #     # Performance
  #     --threads=0
  #     --max-filesize=50M

  #     # Global excludes
  #     --glob=!.git
  #     --glob=!node_modules
  #     --glob=!target
  #     --glob=!dist
  #     --glob=!build
  #     --glob=!*.min.js
  #     --glob=!*.map
  #     --glob=!package-lock.json
  #     --glob=!yarn.lock
  #     --glob=!Cargo.lock
  #   '';
  # };

  # # Ripgrep ignore patterns
  # home.file.".config/ripgrep/ignore" = {
  #   text = ''
  #     # Version control
  #     .git/
  #     .svn/
  #     .hg/

  #     # Dependencies
  #     node_modules/
  #     vendor/
  #     target/

  #     # Build outputs
  #     dist/
  #     build/
  #     out/
  #     .next/
  #     .nuxt/

  #     # Virtual environments
  #     .venv/
  #     venv/
  #     env/

  #     # IDE
  #     .idea/
  #     .vscode/
  #     *.swp
  #     *.swo
  #     *~

  #     # OS files
  #     .DS_Store
  #     Thumbs.db

  #     # Large/binary files
  #     *.zip
  #     *.tar.*
  #     *.rar
  #     *.7z
  #     *.pdf
  #     *.exe
  #     *.dll
  #     *.so

  #     # Cache
  #     .cache/
  #     *.cache
  #     __pycache__/
  #     *.pyc
  #   '';
  # };
}
