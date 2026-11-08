{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
      testTools = with pkgs; [
        python
        bash
        coreutils
        jq
        openssh
      ];
    in
    {
      checks.script-regressions =
        pkgs.runCommand "script-regressions" { nativeBuildInputs = testTools; }
          ''
            export PYTHONDONTWRITEBYTECODE=1
            unset SING_BOX SUB2SINGBOX
            python3 -m unittest discover -s ${self}/tests -v
            touch "$out"
          '';

      devShells.tests = pkgs.mkShellNoCC {
        packages =
          testTools
          ++ [
            pkgs.git
            pkgs.nix
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.iproute2
            pkgs.util-linux
          ];
      };
    };
}
