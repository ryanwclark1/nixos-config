{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [ 
    discord 
    discocss 
  ];

  xdg.configFile."discocss/custom.css" = {
    source = ./custom.css;
    executable = false;
  };

}
