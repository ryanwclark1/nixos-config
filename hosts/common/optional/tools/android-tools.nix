{
  pkgs,
  ...
}:

{
  # programs.adb.enable is obsolete in newer nixpkgs as systemd handles uaccess rules
  environment.systemPackages = [ pkgs.android-tools ];
}
