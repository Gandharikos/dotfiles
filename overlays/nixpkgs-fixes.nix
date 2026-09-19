{ inputs, ... }:
{
  nixpkgs-fixes = final: prev: {
    # d2 only uses Chromium for image export; avoid pulling in the broken
    # Playwright WebKit package (missing libmanette in nixpkgs).
    d2 = prev.d2.override {
      playwright-driver = prev.playwright-driver // {
        browsers = prev.playwright-driver.browsers-chromium;
      };
    };

    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (_pythonFinal: pythonPrev: {
        mpv = pythonPrev.mpv.overridePythonAttrs (_old: {
          # python-mpv 1.0.8 has an environment-sensitive concurrency test that
          # fails under Python 3.14 in the Nix build sandbox.
          doCheck = false;
        });
      })
    ];

    vulkan-validation-layers =
      (final.callPackage (inputs.nixpkgs + "/pkgs/by-name/vu/vulkan-validation-layers/package.nix") { })
      .overrideAttrs
        (old: {
          # 1.4.350.0 defaults UPDATE_DEPS=ON and tries to run git clone during
          # configure, even though nixpkgs already provides the required deps.
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DUPDATE_DEPS=OFF" ];
        });
  };
}
