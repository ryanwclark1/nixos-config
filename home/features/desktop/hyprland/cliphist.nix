{
  pkgs,
  ...
}:

{
  services.cliphist = {
    enable = false;
    package = pkgs.cliphist;
    allowImages = true;
    extraOptions = [
      "-max-dedupe-search"
      "10"
      "-max-items"
      "500"
    ];
  };
}