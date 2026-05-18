{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.zotero;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.zotero = {
    enable = mkEnableOption "Zotero" // {
      default = false;
    };
  };

  config = mkIf enable {
    home.packages = with pkgs; [
      zotero
      tesseract
    ];
  };
}
