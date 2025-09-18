{
  ...
}:

{
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
}
