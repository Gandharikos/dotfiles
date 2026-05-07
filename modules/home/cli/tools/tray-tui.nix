{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.tray-tui;
in
{
  options.my.tray-tui = {
    enable = mkEnableOption "tray-tui";
  };

  config = mkIf cfg.enable {
    programs.tray-tui = {
      enable = true;
    };
  };
}
