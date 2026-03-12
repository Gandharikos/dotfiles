{
  lib,
  config,
  ...
}: let
  cfg = config.my.tealdeer;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in {
  options.my.tealdeer = {
    enable = mkEnableOption "tealdeer";
  };

  config = mkIf cfg.enable {
    programs.tealdeer = {
      enable = true;
      settings = {
        display = {
          compact = true;
          use_pager = true;
        };
        updates = {
          auto_update = true;
          auto_update_interval_hours = 24;
        };
      };
    };
  };
}
