{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.zotero;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.zotero = {
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
