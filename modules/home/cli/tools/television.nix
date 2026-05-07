{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.dot.television;
in
{
  options.dot.television = {
    enable = mkEnableOption "television";
  };

  config = mkIf cfg.enable {
    programs.television = {
      enable = true;

      settings = {
        ui = {
          use_nerd_font_icons = true;
        };
      };
    };
  };
}
