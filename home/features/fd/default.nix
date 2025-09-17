{
  pkgs,
  ...
}:

{
  programs.fd = {
    enable = true;
    package = pkgs.fd;
    hidden = true;
    ignores = [
      ".git"
      ".svn"
      ".direnv"
      "node_modules"
      "target"
      "build"
      "dist"
      "out"
      ".venv"
      "venv"
      "__pycache__"
      "*.pyc"
      ".cache"
      ".mypy_cache"
      ".pytest_cache"
      ".ruff_cache"
      ".terraform"
      ".next"
      ".pnpm-store"
      "coverage"
      ".DS_Store"
      "Thumbs.db"
    ];
    extraOptions = [
      "--color=auto"
      "--follow"
      "--no-require-git"
      # "--hyperlink=auto"
    ];
  };
}
