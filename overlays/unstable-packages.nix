{ inputs }: final: prev: {
  unstable = import inputs.nixpkgs {
    inherit (final) system;
    config.allowUnfree = true;
  };
}