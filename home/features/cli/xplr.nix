{
  config,
  pkgs,
  lib,
  ...
}:


{

  programs.xplr = {
    extraConfig = ''
      -- xpm
      local home = os.getenv("HOME")
      local xpm_path = home .. "/.local/share/xplr/dtomvan/xpm.xplr"
      local xpm_url = "https://github.com/dtomvan/xpm.xplr"

      package.path = package.path
        .. ";"
        .. xpm_path
        .. "/?.lua;"
        .. xpm_path
        .. "/?/init.lua"

      os.execute(
        string.format(
          "[ -e '%s' ] || git clone '%s' '%s'",
          xpm_path,
          xpm_url,
          xpm_path
        )
      )

      -- plugins setup
      require("xpm").setup({
        plugins = {
          -- Let xpm manage itself
          'dtomvan/xpm.xplr',
          {
            'sayanarijit/tri-pane.xplr',
            setup = function()
              require 'tri-pane'.setup {
                as_default_layout = true
              }
            end
          },
          'Junker/nuke.xplr'
        },
        auto_install = true,
        auto_cleanup = true,
      })
    '';
  };

}
