{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.meta) getExe getExe';

  # Define a function that creates wrapper scripts to track impure program calls
  mkTracer =
    name: target: exe:
    # Log the PID of the calling process and the target executable
    # Execute the original program with original arguments
    getExe (
      pkgs.writeShellScriptBin name ''
        echo "PID $PPID executed ${target}" |& ${getExe' config.systemd.package "systemd-cat"} --identifier=impurity >/dev/null 2>/dev/null
        exec -a "$0" '${exe}' "$@"
      ''
    );
in
{
  environment = {
    usrbinenv = mkTracer "env" "/usr/bin/env" "${getExe' pkgs.coreutils "env"}";
    binsh = mkTracer "sh" "/bin/sh" "${getExe' pkgs.bashInteractive "sh"}";
  };
}
