let
  pname = "cursor";
  version = "2.2.20";

  inherit (stdenvNoCC) hostPlatform;

  sources = {
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/linux/arm64/Cursor-2.2.20-aarch64.AppImage";
      hash = "sha256-7z5z8v7UWj3hUWv9q7SvXlRUb859JhLTP73MIyjKS30=";
    };
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/linux/x64/Cursor-2.2.20-x86_64.AppImage";
      hash = "sha256-dY42LaaP7CRbqY2tuulJOENa+QUGSL09m07PvxsZCr0=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-6nb6Q5h9LK0zblD0acg+PO3NPqpe6vstgKllIuhWfTw=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/b3573281c4775bfc6bba466bf6563d3d498d1074/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-7EApheXkyDrEDCCF66uh0v1dkk3Ha6RnWR7K0OVI7M4=";
    };
  };

in
  sources.${hostPlatform.system}
