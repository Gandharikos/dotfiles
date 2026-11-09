let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  inherit (flake.inputs.nixpkgs) lib;
  tyr = flake.darwinConfigurations.tyr.config;
  eir = flake.darwinConfigurations.eir.config;
  hasKrd = config: lib.any (package: lib.getName package == "krd") config.environment.systemPackages;
in
{
  darwinOnly =
    assert flake.packages.aarch64-darwin ? krd;
    assert !(flake.packages.aarch64-linux ? krd);
    assert !(flake.packages.x86_64-linux ? krd);
    true;
  tyrOnly =
    assert hasKrd tyr;
    assert !(hasKrd eir);
    assert lib.all (host: !(hasKrd host.config)) (builtins.attrValues flake.nixosConfigurations);
    true;
  pinnedBinary =
    let
      package = flake.packages.aarch64-darwin.krd;
    in
    assert package.version == "0.3.0";
    assert package.src.outputHash == "sha256-tkYdyAisJt/Ikj0qW9lHGW/JN7yTD9Kaf64tAttClxo=";
    assert package.meta.sourceProvenance == [ lib.sourceTypes.binaryNativeCode ];
    assert package.meta.mainProgram == "krd";
    true;
}
