{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.dot.tray-tui;
in
{
  options.dot.tray-tui = {
    enable = mkEnableOption "tray-tui";
  };

  config = mkIf cfg.enable {
    programs.tray-tui = {
      enable = true;
    };
  };
}
