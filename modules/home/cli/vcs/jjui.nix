{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;

  cfg = config.dot.jjui;
in
{
  options.dot.jjui = {
    enable = mkEnableOption "jjui";
  };

  config = mkIf cfg.enable {
    programs.jjui = {
      # Jjui documentation
      # See: https://github.com/idursun/jjui
      enable = true;

      settings = {
        limit = 0;

        preview = {
          show_at_start = true;
          width_percentage = 60.0;
        };

        oplog = {
          limit = 500;
        };

        graph = {
          batch_size = 100;
        };

        ui = {
          tracer.enabled = true;
        };
      };
    };
  };
}
