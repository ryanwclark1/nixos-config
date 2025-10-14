# overlay: add the policy flag to older CMake projects
final: prev: {
  # Fix CMake policy error on recent CMake (>=3.30)
  intel-graphics-compiler = prev.intel-graphics-compiler.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });

  clblast = prev.clblast.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });

  p8-platform = prev.p8-platform.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });

  libvdpau-va-gl = prev.libvdpau-va-gl.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });

  jsonnet = prev.jsonnet.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });

  fw-ectool = prev.fw-ectool.overrideAttrs (old: {
    cmakeFlags = (old.cmakeFlags or []) ++ [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  });
}
