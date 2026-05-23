{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
}:

let
  pname = "antigravity-cli";
  # Read version and sources from a separate file for easier updates
  info = lib.importJSON ./information.json;
  version = info.version;
  
  src = fetchurl {
    inherit (info.sources."${stdenv.hostPlatform.system}" or (throw "Unsupported system: ${stdenv.hostPlatform.system}")) url sha512;
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    installShellFiles
  ] ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp antigravity $out/bin/agy
    chmod +x $out/bin/agy

    ${lib.optionalString stdenv.isLinux ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/agy
    ''}

    # Generate shell completions
    export HOME=$TMPDIR
    $out/bin/agy completion bash > agy.bash
    $out/bin/agy completion zsh > agy.zsh
    $out/bin/agy completion fish > agy.fish

    installShellCompletion agy.bash agy.zsh agy.fish

    runHook postInstall
  '';

  meta = with lib; {
    description = "Official CLI for Antigravity, the agentic development platform";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "agy";
  };
}
