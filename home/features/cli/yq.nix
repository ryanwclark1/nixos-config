{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    yq-go #jq for yaml https://github.com/mikefarah/yq
  ];
}