# This file was generated by nvfetcher, please do not modify it manually.
{ fetchurl, fetchFromGitHub, }: #fetchgit, dockerTools }:
{
  alpine-js-intellisense = {
    pname = "alpine-js-intellisense";
    version = "1.2.0";
    src = fetchurl {
      url = "https://adrianwilczynski.gallery.vsassets.io/_apis/public/gallery/publisher/adrianwilczynski/extension/alpine-js-intellisense/1.2.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "alpine-js-intellisense-1.2.0.zip";
      sha256 = "sha256-Klx5ZvV06lXIJ3Q/mzq3KBjPpdROoxDkgEu7MBO+RhI=";
    };
    publisher = "adrianwilczynski";
    name = "alpine-js-intellisense";
  };
  ansible = {
    pname = "ansible";
    version = "25.2.0";
    src = fetchurl {
      url = "https://redhat.gallery.vsassets.io/_apis/public/gallery/publisher/redhat/extension/ansible/25.2.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "ansible-25.2.0.zip";
      sha256 = "sha256-jgb12UJ+YtBKgdYWtZDq9KXWpsSq6NzMOIMNPGXwDe0=";
    };
    publisher = "redhat";
    name = "ansible";
  };
  bun-vscode = {
    pname = "bun-vscode";
    version = "0.0.26";
    src = fetchurl {
      url = "https://oven.gallery.vsassets.io/_apis/public/gallery/publisher/oven/extension/bun-vscode/0.0.26/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "bun-vscode-0.0.26.zip";
      sha256 = "sha256-klMkKAorWJj2o015FWbQQfpmYe4JM0UOM+WVh+YPtI4=";
    };
    publisher = "oven";
    name = "bun-vscode";
  };
  copilot = {
    pname = "copilot";
    version = "1.271.0";
    src = fetchurl {
      url = "https://github.gallery.vsassets.io/_apis/public/gallery/publisher/github/extension/copilot/1.271.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "copilot-1.271.0.zip";
      sha256 = "sha256-uSN7JUfyi8y0sn7XijgEwDxa+9RsghU3FlNVV3SlHro=";
    };
    publisher = "github";
    name = "copilot";
  };
  copilot-chat = {
    pname = "copilot-chat";
    version = "0.25.2025021301";
    src = fetchurl {
      url = "https://github.gallery.vsassets.io/_apis/public/gallery/publisher/github/extension/copilot-chat/0.25.2025021301/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "copilot-chat-0.25.2025021301.zip";
      sha256 = "sha256-JXjd1y0OotxkcQzl70E6/hiW/0L0jXmjVwoOq9vFad4=";
    };
    publisher = "github";
    name = "copilot-chat";
  };
  explorer = {
    pname = "explorer";
    version = "1.14.0";
    src = fetchurl {
      url = "https://vitest.gallery.vsassets.io/_apis/public/gallery/publisher/vitest/extension/explorer/1.14.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "explorer-1.14.0.zip";
      sha256 = "sha256-74IlnOBrznyQzq9u+s6j2R017XPAkjXZT4h76M+wYCc=";
    };
    publisher = "vitest";
    name = "explorer";
  };
  gopls = {
    pname = "gopls";
    version = "gopls/v0.17.1";
    src = fetchFromGitHub {
      owner = "golang";
      repo = "tools";
      rev = "gopls/v0.17.1";
      fetchSubmodules = false;
      sha256 = "sha256-NLUIFNooOOA4LEL5nZNdP9TvDkQUqLjKi44kZtOxeuI=";
    };
  };
  grafana-vscode = {
    pname = "grafana-vscode";
    version = "0.0.19";
    src = fetchurl {
      url = "https://grafana.gallery.vsassets.io/_apis/public/gallery/publisher/grafana/extension/grafana-vscode/0.0.19/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "grafana-vscode-0.0.19.zip";
      sha256 = "sha256-TpLOMwdaEdgzWVwUcn+fO4rgLiQammWQM8LQobt8gLw=";
    };
    publisher = "grafana";
    name = "grafana-vscode";
  };
  htmx-attributes = {
    pname = "htmx-attributes";
    version = "0.8.0";
    src = fetchurl {
      url = "https://craigrbroughton.gallery.vsassets.io/_apis/public/gallery/publisher/craigrbroughton/extension/htmx-attributes/0.8.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "htmx-attributes-0.8.0.zip";
      sha256 = "sha256-TsemPZkq2Z13/vahRaP7z206BJaCZ1TR6OVv6aeDvyk=";
    };
    publisher = "craigrbroughton";
    name = "htmx-attributes";
  };
  mypy-type-checker = {
    pname = "mypy-type-checker";
    version = "2025.1.10381011";
    src = fetchurl {
      url = "https://ms-python.gallery.vsassets.io/_apis/public/gallery/publisher/ms-python/extension/mypy-type-checker/2025.1.10381011/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "mypy-type-checker-2025.1.10381011.zip";
      sha256 = "sha256-boKUxLOAgQJP13zX/NMhg1MtcrPVQJt5gLbxI7gVSu4=";
    };
    publisher = "ms-python";
    name = "mypy-type-checker";
  };
  prom = {
    pname = "prom";
    version = "1.3.3";
    src = fetchurl {
      url = "https://ventura.gallery.vsassets.io/_apis/public/gallery/publisher/ventura/extension/prom/1.3.3/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "prom-1.3.3.zip";
      sha256 = "sha256-h8pRrPzmu8+5ZiOLALjackr4zWuFAqi1ex7Gp2iOZKk=";
    };
    publisher = "ventura";
    name = "prom";
  };
  rasi = {
    pname = "rasi";
    version = "1.0.0";
    src = fetchurl {
      url = "https://dlasagno.gallery.vsassets.io/_apis/public/gallery/publisher/dlasagno/extension/rasi/1.0.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "rasi-1.0.0.zip";
      sha256 = "sha256-s60alej3cNAbSJxsRlIRE2Qha6oAsmcOBbWoqp+w6fk=";
    };
    publisher = "dlasagno";
    name = "rasi";
  };
  remote-explorer = {
    pname = "remote-explorer";
    version = "0.5.2025010909";
    src = fetchurl {
      url = "https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/remote-explorer/0.5.2025010909/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "remote-explorer-0.5.2025010909.zip";
      sha256 = "sha256-wAxei9TYi23O+KkG6cxoCv9dkJi9FolFTUeDoQCzYB4=";
    };
    publisher = "ms-vscode";
    name = "remote-explorer";
  };
  remotehub = {
    pname = "remotehub";
    version = "0.65.2024112101";
    src = fetchurl {
      url = "https://github.gallery.vsassets.io/_apis/public/gallery/publisher/github/extension/remotehub/0.65.2024112101/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "remotehub-0.65.2024112101.zip";
      sha256 = "sha256-Xb28yff0tiQDUuwC5Mv0rwXqLgZOU4B3KZAht78NfFU=";
    };
    publisher = "github";
    name = "remotehub";
  };
  sqlite-viewer = {
    pname = "sqlite-viewer";
    version = "0.10.1";
    src = fetchurl {
      url = "https://qwtel.gallery.vsassets.io/_apis/public/gallery/publisher/qwtel/extension/sqlite-viewer/0.10.1/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "sqlite-viewer-0.10.1.zip";
      sha256 = "sha256-dEaD2GH7aNWcF3hvXtZ2wh5/IUE1KZzHBgTxIP35ZwI=";
    };
    publisher = "qwtel";
    name = "sqlite-viewer";
  };
  sqltools = {
    pname = "sqltools";
    version = "0.28.3";
    src = fetchurl {
      url = "https://mtxr.gallery.vsassets.io/_apis/public/gallery/publisher/mtxr/extension/sqltools/0.28.3/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "sqltools-0.28.3.zip";
      sha256 = "sha256-bTrHAhj8uwzRIImziKsOizZf8+k3t+VrkOeZrFx7SH8=";
    };
    publisher = "mtxr";
    name = "sqltools";
  };
  sqltools-driver-pg = {
    pname = "sqltools-driver-pg";
    version = "0.5.4";
    src = fetchurl {
      url = "https://mtxr.gallery.vsassets.io/_apis/public/gallery/publisher/mtxr/extension/sqltools-driver-pg/0.5.4/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "sqltools-driver-pg-0.5.4.zip";
      sha256 = "sha256-XnPTMFNgMGT2tJe8WlmhMB3DluvMZx9Ee2w7xMCzLYM=";
    };
    publisher = "mtxr";
    name = "sqltools-driver-pg";
  };
  sqltools-driver-sqlite = {
    pname = "sqltools-driver-sqlite";
    version = "0.5.1";
    src = fetchurl {
      url = "https://mtxr.gallery.vsassets.io/_apis/public/gallery/publisher/mtxr/extension/sqltools-driver-sqlite/0.5.1/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "sqltools-driver-sqlite-0.5.1.zip";
      sha256 = "sha256-wFgb6wDSgPbPtEVKbHcUeURqbVAqDsEEhFUcBhQtmF8=";
    };
    publisher = "mtxr";
    name = "sqltools-driver-sqlite";
  };
  tailwind-color-matcher = {
    pname = "tailwind-color-matcher";
    version = "1.0.8";
    src = fetchurl {
      url = "https://OmriGrossman.gallery.vsassets.io/_apis/public/gallery/publisher/OmriGrossman/extension/tailwind-color-matcher/1.0.8/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "tailwind-color-matcher-1.0.8.zip";
      sha256 = "sha256-WfFg1h5tY43W9YqgXkHDlxjRquFupuvLBwotTw0XoNk=";
    };
    publisher = "OmriGrossman";
    name = "tailwind-color-matcher";
  };
  tailwind-docs = {
    pname = "tailwind-docs";
    version = "2.1.0";
    src = fetchurl {
      url = "https://austenc.gallery.vsassets.io/_apis/public/gallery/publisher/austenc/extension/tailwind-docs/2.1.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "tailwind-docs-2.1.0.zip";
      sha256 = "sha256-EB3ggxo2NqiH8yVpsNzDRb+fvsd6Qd5aXRM6FoZn5k8=";
    };
    publisher = "austenc";
    name = "tailwind-docs";
  };
  tailwind-fold = {
    pname = "tailwind-fold";
    version = "0.2.0";
    src = fetchurl {
      url = "https://stivo.gallery.vsassets.io/_apis/public/gallery/publisher/stivo/extension/tailwind-fold/0.2.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "tailwind-fold-0.2.0.zip";
      sha256 = "sha256-yH3eA5jgBwxqnpFQkg91KQMkQps5iM1v783KQkQcWUU=";
    };
    publisher = "stivo";
    name = "tailwind-fold";
  };
  templ = {
    pname = "templ";
    version = "0.0.33";
    src = fetchurl {
      url = "https://a-h.gallery.vsassets.io/_apis/public/gallery/publisher/a-h/extension/templ/0.0.33/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "templ-0.0.33.zip";
      sha256 = "sha256-Q9ZM3DPxB5bW/ob+aTgQZCl1OaSDvDGluqhqd4k8GIM=";
    };
    publisher = "a-h";
    name = "templ";
  };
  vscode-gitops-tools = {
    pname = "vscode-gitops-tools";
    version = "0.27.0";
    src = fetchurl {
      url = "https://weaveworks.gallery.vsassets.io/_apis/public/gallery/publisher/weaveworks/extension/vscode-gitops-tools/0.27.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "vscode-gitops-tools-0.27.0.zip";
      sha256 = "sha256-7MCKDnHCot/CL/SqZ2WuTxbqFdF75EC5WC+OxW0dcaE=";
    };
    publisher = "weaveworks";
    name = "vscode-gitops-tools";
  };
  vscode-jsonnet = {
    pname = "vscode-jsonnet";
    version = "0.7.2";
    src = fetchurl {
      url = "https://grafana.gallery.vsassets.io/_apis/public/gallery/publisher/grafana/extension/vscode-jsonnet/0.7.2/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "vscode-jsonnet-0.7.2.zip";
      sha256 = "sha256-Q8VzXzTdHo9h5+eCHHF1bPomPEbRsvouJcUfmFUDGMU=";
    };
    publisher = "grafana";
    name = "vscode-jsonnet";
  };
  vscode-postgresql-client2 = {
    pname = "vscode-postgresql-client2";
    version = "8.1.4";
    src = fetchurl {
      url = "https://cweijan.gallery.vsassets.io/_apis/public/gallery/publisher/cweijan/extension/vscode-postgresql-client2/8.1.4/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "vscode-postgresql-client2-8.1.4.zip";
      sha256 = "sha256-hfsYLvE0itiRZD9lzMSNTwcMeYgrwKRY+hX+nFLvIeI=";
    };
    publisher = "cweijan";
    name = "vscode-postgresql-client2";
  };
  vscode-speech = {
    pname = "vscode-speech";
    version = "0.12.1";
    src = fetchurl {
      url = "https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publisher/ms-vscode/extension/vscode-speech/0.12.1/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "vscode-speech-0.12.1.zip";
      sha256 = "sha256-fxmaPI7uq7DQlzgJc8RcZzHDOwMuodSCf9TkLU9+/+k=";
    };
    publisher = "ms-vscode";
    name = "vscode-speech";
  };
  vscode-thunder-client = {
    pname = "vscode-thunder-client";
    version = "2.34.1";
    src = fetchurl {
      url = "https://rangav.gallery.vsassets.io/_apis/public/gallery/publisher/rangav/extension/vscode-thunder-client/2.34.1/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "vscode-thunder-client-2.34.1.zip";
      sha256 = "sha256-dz7wf6GecpRBQCuZXfwRDGIEbVYCaptWi7nxKUveFTI=";
    };
    publisher = "rangav";
    name = "vscode-thunder-client";
  };
  yuck = {
    pname = "yuck";
    version = "0.0.3";
    src = fetchurl {
      url = "https://eww-yuck.gallery.vsassets.io/_apis/public/gallery/publisher/eww-yuck/extension/yuck/0.0.3/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
      name = "yuck-0.0.3.zip";
      sha256 = "sha256-DITgLedaO0Ifrttu+ZXkiaVA7Ua5RXc4jXQHPYLqrcM=";
    };
    publisher = "eww-yuck";
    name = "yuck";
  };
}
