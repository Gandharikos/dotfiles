{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (config.my.machine) monitors;
  cfg = config.my.gui.desktop.niri;

  isResolution = value: builtins.match "^[0-9]+x[0-9]+(@[0-9.]+)?$" value != null;
  isPosition = value: builtins.match "^(-?[0-9]+)x(-?[0-9]+)$" value != null;
  toInt = value: builtins.fromJSON value;
  parsePosition = value: let
    match = builtins.match "^(-?[0-9]+)x(-?[0-9]+)$" value;
  in {
    x = toInt (builtins.elemAt match 0);
    y = toInt (builtins.elemAt match 1);
  };

  mkOutput = output:
    {
      inherit (output) scale;
    }
    // optionalAttrs (isResolution output.resolution) {
      mode = output.resolution;
    }
    // optionalAttrs (isPosition output.position) {
      position = parsePosition output.position;
    };

  outputs =
    builtins.listToAttrs
    (builtins.map (output: {
        inherit (output) name;
        value = mkOutput output;
      })
      monitors);
in {
  config = mkIf cfg.enable {
    programs.niri.settings.outputs = outputs;
  };
}
