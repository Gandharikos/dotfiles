{
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (osConfig.dot.machine) monitors;
  cfg = config.my.gui.desktop.niri;

  isResolution = value: builtins.match "^[0-9]+x[0-9]+(@[0-9.]+)?$" value != null;
  isPosition = value: builtins.match "^(-?[0-9]+)x(-?[0-9]+)$" value != null;
  toInt = value: builtins.fromJSON value;
  toFloat =
    value: builtins.fromJSON (if builtins.match "^[0-9]+$" value != null then "${value}.0" else value);
  parseResolution =
    value:
    let
      match = builtins.match "^([0-9]+)x([0-9]+)(@([0-9.]+))?$" value;
      refresh = builtins.elemAt match 3;
    in
    {
      width = toInt (builtins.elemAt match 0);
      height = toInt (builtins.elemAt match 1);
    }
    // optionalAttrs (refresh != null) {
      refresh = toFloat refresh;
    };
  parsePosition =
    value:
    let
      match = builtins.match "^(-?[0-9]+)x(-?[0-9]+)$" value;
    in
    {
      x = toInt (builtins.elemAt match 0);
      y = toInt (builtins.elemAt match 1);
    };

  mkOutput =
    output:
    {
      inherit (output) scale;
    }
    // optionalAttrs (isResolution output.resolution) {
      mode = parseResolution output.resolution;
    }
    // optionalAttrs (isPosition output.position) {
      position = parsePosition output.position;
    };

  outputs = builtins.listToAttrs (
    builtins.map (output: {
      inherit (output) name;
      value = mkOutput output;
    }) monitors
  );
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.outputs = outputs;
  };
}
