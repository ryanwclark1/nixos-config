{
  # inputs,
  # pkgs,
  ...
}:

{
  imports = [./languages.nix];

  # programs.helix = {
  #   enable = true;
  #   package = inputs.helix.packages.${pkgs.system}.default.overrideAttrs (old: {
  #     makeWrapperArgs = with pkgs;
  #       old.makeWrapperArgs
  #       or []
  #       ++ [
  #         "--suffix"
  #         "PATH"
  #         ":"
  #         (lib.makeBinPath [
  #           clang-tools
  #           marksman
  #           nil
  #           bash-language-server
  #           nodePackages.vscode-css-languageserver-bin
  #           nodePackages.vscode-langservers-extracted
  #           shellcheck
  #         ])
  #       ];
  #   });

  #   settings = {
  #     editor = {
  #       color-modes = true;
  #       cursorline = true;
  #       line-number = "relative";
  #       indent-guides.render = true;
  #       cursor-shape = {
  #         normal = "block";
  #         insert = "bar";
  #         select = "underline";
  #       };
  #       lsp.display-inlay-hints = true;
  #       statusline.center = ["position-percentage"];
  #       true-color = true;
  #       whitespace.characters = {
  #         newline = "↴";
  #         tab = "⇥";
  #       };
  #     };
  #     keys.normal.space.u = {
  #       f = ":format"; # format using LSP formatter
  #       w = ":set whitespace.render all";
  #       W = ":set whitespace.render none";
  #     };
  #   };
  # };
}
