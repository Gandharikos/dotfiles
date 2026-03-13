{lib, ...}: let
  getProgramName = program: builtins.baseNameOf program;
  shellEscape = lib.strings.escapeShellArgs;

  shellScript = pkgs: name: text: pkgs.writeShellScript name text;

  shellScriptArgs = pkgs: name: text: [shellScript pkgs name text];

  uwsmAppArgs = pkgs: exe: args: let
    uwsm' = lib.getExe pkgs.uwsm;
  in
    [uwsm' "app" "--" exe] ++ args;

  uwsmApp = pkgs: exe: args: shellEscape (uwsmAppArgs pkgs exe args);

  uwsmScriptPath = pkgs: name: text: shellScript pkgs name text;

  uwsmScriptArgs = pkgs: name: text: let
    script = uwsmScriptPath pkgs name text;
  in
    uwsmAppArgs pkgs script [];

  uwsmScript = pkgs: name: text: let
    script = uwsmScriptPath pkgs name text;
  in
    uwsmApp pkgs script [];

  toggleCommand = pkgs: program': let
    programName = getProgramName program';
    pkill' = lib.getExe' pkgs.procps "pkill";
  in "${pkill'} -x ${programName} || ${uwsmApp pkgs program' []}";

  toggleCommandArgs = pkgs: program': let
    programName = getProgramName program';
    script = shellScript pkgs "toggle-${programName}" ''
      ${toggleCommand pkgs program'}
    '';
  in [script];

  runOnceCommand = pkgs: program': let
    programName = getProgramName program';
    pidof' = lib.getExe' pkgs.procps "pidof";
  in "${pidof'} ${programName} > /dev/null || ${uwsmApp pkgs program' []}";

  runOnceCommandArgs = pkgs: program': let
    programName = getProgramName program';
    script = shellScript pkgs "run-once-${programName}" ''
      ${runOnceCommand pkgs program'}
    '';
  in [script];

  withProgram = pkgs: program:
    lib.getExe (builtins.getAttr program pkgs);

  withPackageProgram = package: program:
    lib.getExe' package program;

  toggle = pkgs: program:
    toggleCommand pkgs (withProgram pkgs program);

  toggle' = pkgs: package: program:
    toggleCommand pkgs (withPackageProgram package program);

  toggleArg = pkgs: program:
    toggleCommandArgs pkgs (withProgram pkgs program);

  toggleArg' = pkgs: package: program:
    toggleCommandArgs pkgs (withPackageProgram package program);

  runOnce = pkgs: program:
    runOnceCommand pkgs (withProgram pkgs program);

  runOnce' = pkgs: package: program:
    runOnceCommand pkgs (withPackageProgram package program);

  runOnceArg = pkgs: program:
    runOnceCommandArgs pkgs (withProgram pkgs program);

  runOnceArg' = pkgs: package: program:
    runOnceCommandArgs pkgs (withPackageProgram package program);

  withUWSM = pkgs: program:
    uwsmApp pkgs (withProgram pkgs program) [];

  withUWSM' = pkgs: package: program:
    uwsmApp pkgs (withPackageProgram package program) [];

  withUWSMArgs = pkgs: program:
    uwsmAppArgs pkgs (withProgram pkgs program) [];

  withUWSMArgs' = pkgs: package: program:
    uwsmAppArgs pkgs (withPackageProgram package program) [];
in {
  inherit
    shellScript
    shellScriptArgs
    uwsmApp
    uwsmAppArgs
    uwsmScript
    uwsmScriptArgs
    toggle
    toggle'
    toggleArg
    toggleArg'
    runOnce
    runOnce'
    runOnceArg
    runOnceArg'
    withUWSM
    withUWSM'
    withUWSMArgs
    withUWSMArgs'
    ;
}
