{
  ...
}:

{
  programs.btop = {
    enable = true;

    settings = {
      vim_keys = true;
      update_ms = 1000;
      disks_filter = "";
      proc_per_core = true;
    };
  };

  home.shellAliases = {
    htop = "btop";
    top = "btop";
  };

}