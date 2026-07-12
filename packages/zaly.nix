{
  lib,
  buildNpmPackage,
  importNpmLock,
  nodejs_22,
  runCommand,
  writeText,
  ...
}:
let
  pname = "zaly";
  version = "0.0.5";

  package = {
    name = pname;
    inherit version;
    private = true;
    type = "module";
    bin.zaly = "node_modules/@zaly/cli/dist/zaly.mjs";
    dependencies."@zaly/cli" = version;
    engines.node = ">=22.11";
  };

  packageLock = builtins.fromJSON (builtins.readFile ./zaly-package-lock.json);
  packageJson = writeText "package.json" (builtins.toJSON package);

  src = runCommand "${pname}-${version}-source" { } ''
    mkdir -p $out
    cp ${packageJson} $out/package.json
    cp ${./zaly-package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  inherit pname version src;

  nodejs = nodejs_22;
  npmDeps = importNpmLock {
    inherit package packageLock;
  };
  inherit (importNpmLock) npmConfigHook;

  dontNpmBuild = true;

  meta = {
    description = "Hackable terminal coding agent";
    homepage = "https://github.com/folke/zaly";
    license = lib.licenses.mit;
    mainProgram = "zaly";
    platforms = nodejs_22.meta.platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
