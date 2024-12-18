# { inputs }: final: prev: {
#   vscode = prev.vscode.overrideAttrs (_: rec {
#     version = "1.90.2";
#     plat = "linux-x64";
#     archive_fmt = "tar.gz";
#     pname = "vscode";
#     src = prev.fetchurl {
#       url = "https://update.code.visualstudio.com/${version}/${plat}/stable";
#       sha256 = "bc15c4bf497c569af0726c218328c6ffe85a2189f544897be52157a7a27e0c34";
#       name = "VSCode_${version}_${plat}.${archive_fmt}";
#     };
#   });
# }