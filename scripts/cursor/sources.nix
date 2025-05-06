let
  pname = "cursor";
  version = "0.48.9";

  inherit (stdenvNoCC) hostPlatform;

  sources = {
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/61e99179e4080fecf9d8b92c6e2e3e00fbfb53f4/linux/arm64/Cursor-0.48.9-aarch64.AppImage";
      hash = "sha256-RMDYoQSIO0jukhC5j1TjpwCcK0tEnvoVpXbFOxp/K8o=";
    };
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/61e99179e4080fecf9d8b92c6e2e3e00fbfb53f4/linux/x64/Cursor-0.48.9-x86_64.AppImage";
      hash = "sha256-Rw96CIN+vL1bIj5o68gWkHeiqgxExzbjwcW4ad10M2I=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/61e99179e4080fecf9d8b92c6e2e3e00fbfb53f4/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-172BGNNVvpZhk99rQN19tTsxvRADjmtEzgkZazke/v4=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/61e99179e4080fecf9d8b92c6e2e3e00fbfb53f4/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-IQ4UZwEBVGMaGUrNVHWxSRjbw8qhLjOJ2KYc9Y26LZU=";
    };
  };

in
  sources.${hostPlatform.system}
