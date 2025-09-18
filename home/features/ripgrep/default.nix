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
      "--no-ignore-parent"  # Use .gitignore files

      # Exclude patterns
      "--glob=!.git/*"
      "--glob=!.svn/*"
      "--glob=!node_modules/*"
      "--glob=!.npm/*"
      "--glob=!vendor/*"
      "--glob=!dist/*"
      "--glob=!build/*"
      "--glob=!target/*"
      "--glob=!.venv/*"
      "--glob=!venv/*"
      "--glob=!.next/*"
      "--glob=!.nuxt/*"
      "--glob=!.cache/*"
      "--glob=!.vscode/*"
      "--glob=!.idea/*"
      "--glob=!/proc"
      "--glob=!/sys"
      "--glob=!*.min.js"
      "--glob=!*.min.css"
      "--glob=!*.map"

      # Colors
      "--colors=line:fg:yellow"
      "--colors=line:style:bold"
      "--colors=path:fg:green"
      "--colors=path:style:bold"
      "--colors=match:fg:red"
      "--colors=match:style:bold"

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
      "--type-add=vue:*.vue"
      "--type-add=scss:*.scss"
    ];
  };

  # Ripgrep-all for searching in PDFs, Office docs, archives, etc.
  programs.ripgrep-all = {
    enable = true;
    package = pkgs.ripgrep-all;

    # Note: ripgrep-all in Home Manager may have limited custom adapter support
    # The configuration below is commented out due to option compatibility issues
    # For advanced adapters, consider using a standalone ripgrep-all config file
    
    # custom_adapters = [
    #   # Enhanced PDF adapter with OCR support
    #   {
    #     name = "pdf-enhanced";
    #     description = "PDF text extraction with fallback to OCR";
    #     extensions = [ "pdf" ];
    #     command = "${pkgs.poppler_utils}/bin/pdftotext";
    #     args = [ "-layout" "-nopgbrk" "-" "-" ];
    #     binary = false;
    #   }
    # ];
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
