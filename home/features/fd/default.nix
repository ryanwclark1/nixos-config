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
      ".direnv"
      "node_modules"
      "target"
      "build"
      "dist"
      "out"
      ".venv"
      "venv"
      "__pycache__"
      ".cache"
      ".mypy_cache"
      ".pytest_cache"
      ".ruff_cache"
      ".terraform"
      ".next"
      ".pnpm-store"
      "coverage"
    ];
    extraOptions = [
      "--color=auto"
      "--follow"
      "--no-require-git"
      # "--hyperlink=auto"
    ];
  };
}
